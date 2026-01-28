import ClawdbotChatUI
import ClawdbotKit
import ClawdbotProtocol
import Foundation
import OSLog

private let healthLogger = Logger(subsystem: "com.clawdbot", category: "HealthCheck")
private let historyLogger = Logger(subsystem: "com.clawdbot", category: "HistoryRPC")
private let sendLogger = Logger(subsystem: "com.clawdbot", category: "SendRPC")
private let eventLogger = Logger(subsystem: "com.clawdbot", category: "EventStream")

struct IOSGatewayChatTransport: ClawdbotChatTransport, Sendable {
    private let gateway: GatewayNodeSession

    init(gateway: GatewayNodeSession) {
        self.gateway = gateway
    }

    func abortRun(sessionKey: String, runId: String) async throws {
        struct Params: Codable {
            var sessionKey: String
            var runId: String
        }
        let data = try JSONEncoder().encode(Params(sessionKey: sessionKey, runId: runId))
        let json = String(data: data, encoding: .utf8)
        _ = try await self.gateway.request(method: "chat.abort", paramsJSON: json, timeoutSeconds: 10)
    }

    func listSessions(limit: Int?) async throws -> ClawdbotChatSessionsListResponse {
        struct Params: Codable {
            var includeGlobal: Bool
            var includeUnknown: Bool
            var limit: Int?
        }
        let data = try JSONEncoder().encode(Params(includeGlobal: true, includeUnknown: false, limit: limit))
        let json = String(data: data, encoding: .utf8)
        let res = try await self.gateway.request(method: "sessions.list", paramsJSON: json, timeoutSeconds: 15)
        return try JSONDecoder().decode(ClawdbotChatSessionsListResponse.self, from: res)
    }

    func setActiveSessionKey(_ sessionKey: String) async throws {
        struct Subscribe: Codable { var sessionKey: String }
        let data = try JSONEncoder().encode(Subscribe(sessionKey: sessionKey))
        let json = String(data: data, encoding: .utf8)
        await self.gateway.sendEvent(event: "chat.subscribe", payloadJSON: json)
    }

    func requestHistory(sessionKey: String) async throws -> ClawdbotChatHistoryPayload {
        struct Params: Codable { var sessionKey: String }
        let data = try JSONEncoder().encode(Params(sessionKey: sessionKey))
        let json = String(data: data, encoding: .utf8)
        historyLogger.error("[HISTORY-RPC] Requesting history for sessionKey=\(sessionKey)")
        let res = try await self.gateway.request(method: "chat.history", paramsJSON: json, timeoutSeconds: 15)
        historyLogger.error("[HISTORY-RPC] Received \(res.count) bytes")

        // Log first 1000 chars of raw response to see what gateway returns
        if let rawJson = String(data: res, encoding: .utf8) {
            let preview = String(rawJson.prefix(1000))
            historyLogger.error("[HISTORY-RPC] Raw response preview: \(preview, privacy: .public)")
        }

        let decoded = try JSONDecoder().decode(ClawdbotChatHistoryPayload.self, from: res)
        let sk = decoded.sessionKey ?? "nil"
        let sid = decoded.sessionId ?? "nil"
        historyLogger.error("[HISTORY-RPC] Decoded: sk=\(sk) sid=\(sid) msgs=\(decoded.messages?.count ?? 0)")
        return decoded
    }

    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [ClawdbotChatAttachmentPayload]) async throws -> ClawdbotChatSendResponse
    {
        struct Params: Codable {
            var sessionKey: String
            var message: String
            var thinking: String
            var attachments: [ClawdbotChatAttachmentPayload]?
            var timeoutMs: Int
            var idempotencyKey: String
        }

        let params = Params(
            sessionKey: sessionKey,
            message: message,
            thinking: thinking,
            attachments: attachments.isEmpty ? nil : attachments,
            timeoutMs: 30000,
            idempotencyKey: idempotencyKey)
        let data = try JSONEncoder().encode(params)
        let json = String(data: data, encoding: .utf8)
        sendLogger.error("[SEND-RPC] Sending message to sessionKey=\(sessionKey), message='\(message.prefix(50), privacy: .public)'")
        let res = try await self.gateway.request(method: "chat.send", paramsJSON: json, timeoutSeconds: 35)
        sendLogger.error("[SEND-RPC] Received \(res.count) bytes")
        if let rawJson = String(data: res, encoding: .utf8) {
            sendLogger.error("[SEND-RPC] Raw response: \(rawJson.prefix(500), privacy: .public)")
        }
        let decoded = try JSONDecoder().decode(ClawdbotChatSendResponse.self, from: res)
        sendLogger.error("[SEND-RPC] Decoded: runId=\(decoded.runId), status=\(decoded.status ?? "nil", privacy: .public)")
        return decoded
    }

    func requestHealth(timeoutMs: Int) async throws -> Bool {
        let seconds = max(1, Int(ceil(Double(timeoutMs) / 1000.0)))
        healthLogger.error("[HEALTH-RPC] Starting request with timeout \(seconds)s")
        let startTime = Date()
        do {
            let res = try await self.gateway.request(method: "health", paramsJSON: nil, timeoutSeconds: seconds)
            let elapsed = Date().timeIntervalSince(startTime)
            healthLogger.error("[HEALTH-RPC] Response received: \(res.count) bytes in \(String(format: "%.2f", elapsed))s")
            if let json = String(data: res, encoding: .utf8) {
                let preview = String(json.prefix(500))
                healthLogger.error("[HEALTH-RPC] Response preview: \(preview, privacy: .public)")
            }
            let decoded = try? JSONDecoder().decode(ClawdbotGatewayHealthOK.self, from: res)
            let ok = decoded?.ok ?? true
            healthLogger.error("[HEALTH-RPC] Decoded ok=\(ok)")
            return ok
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            healthLogger.error("[HEALTH-RPC] Request FAILED after \(String(format: "%.2f", elapsed))s: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func events() -> AsyncStream<ClawdbotChatTransportEvent> {
        AsyncStream { continuation in
            let task = Task {
                let stream = await self.gateway.subscribeServerEvents()
                for await evt in stream {
                    if Task.isCancelled { return }
                    switch evt.event {
                    case "tick":
                        continuation.yield(.tick)
                    case "seqGap":
                        continuation.yield(.seqGap)
                    case "health":
                        guard let payload = evt.payload else { break }
                        let ok = (try? GatewayPayloadDecoding.decode(
                            payload,
                            as: ClawdbotGatewayHealthOK.self))?.ok ?? true
                        continuation.yield(.health(ok: ok))
                    case "chat":
                        guard let payload = evt.payload else { break }
                        if let chatPayload = try? GatewayPayloadDecoding.decode(
                            payload,
                            as: ClawdbotChatEventPayload.self)
                        {
                            let hasMsg = chatPayload.message != nil
                            let rid = chatPayload.runId ?? "nil"
                            let st = chatPayload.state ?? "nil"
                            let sk = chatPayload.sessionKey ?? "nil"
                            eventLogger.error("[EVENT] chat: rid=\(rid) st=\(st) sk=\(sk) msg=\(hasMsg)")
                            continuation.yield(.chat(chatPayload))
                        }
                    case "agent":
                        guard let payload = evt.payload else { break }
                        if let agentPayload = try? GatewayPayloadDecoding.decode(
                            payload,
                            as: ClawdbotAgentEventPayload.self)
                        {
                            continuation.yield(.agent(agentPayload))
                        }
                    default:
                        break
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
