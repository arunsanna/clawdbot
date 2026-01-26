import Foundation

/// Lightweight utility for checking if a local gateway is running.
/// Used to prevent the macOS app from overwriting config when a local gateway is active.
enum GatewayProcessChecker {
    /// Check if a local gateway appears to be running on the configured port.
    /// This uses PortGuardian to detect a listener and checks the process name.
    static func isLocalGatewayRunning() async -> Bool {
        let port = GatewayEnvironment.gatewayPort()
        guard let descriptor = await PortGuardian.shared.describe(port: port) else {
            return false
        }

        // Check if the listener is a known gateway process (node, clawdbot, tsx, bun, pnpm)
        let command = descriptor.command.lowercased()
        let gatewayCommands = ["node", "clawdbot", "tsx", "bun", "pnpm"]
        return gatewayCommands.contains { command.contains($0) }
    }

    /// Synchronous check using GatewayProcessManager status.
    /// Useful when we can't use async (e.g., from a didSet observer).
    @MainActor
    static func isLocalGatewayRunningSync() -> Bool {
        switch GatewayProcessManager.shared.status {
        case .running, .attachedExisting:
            return true
        case .stopped, .starting, .failed:
            return false
        }
    }
}
