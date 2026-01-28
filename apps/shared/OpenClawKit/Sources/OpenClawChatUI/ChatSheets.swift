import Observation
import SwiftUI

@MainActor
public struct ChatSessionsSheet: View {
    @Bindable public var viewModel: ClawdbotChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewSession = false
    @State private var newSessionName = ""
    @State private var newAgentId = ""
    @State private var isAgentSession = false
    private let onSessionSelected: ((String) -> Void)?

    public init(viewModel: ClawdbotChatViewModel, onSessionSelected: ((String) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSessionSelected = onSessionSelected
    }

    public var body: some View {
        let sessions = self.viewModel.sessions
        NavigationStack {
            List {
                ForEach(sessions, id: \.key) { session in
                    SessionRow(
                        session: session,
                        isActive: session.key == self.viewModel.sessionKey,
                        onSelect: {
                            if let callback = self.onSessionSelected {
                                callback(session.key)
                            } else {
                                self.viewModel.switchSession(to: session.key)
                            }
                            self.dismiss()
                        })
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        self.viewModel.refreshSessions(limit: 200)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        self.showingNewSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                #else
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            self.viewModel.refreshSessions(limit: 200)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            self.showingNewSession = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                #endif
            }
            .onAppear {
                self.viewModel.refreshSessions(limit: 200)
            }
            .sheet(isPresented: self.$showingNewSession) {
                NewSessionSheet(
                    sessionName: self.$newSessionName,
                    agentId: self.$newAgentId,
                    isAgentSession: self.$isAgentSession,
                    onCreate: { sessionKey in
                        if let callback = self.onSessionSelected {
                            callback(sessionKey)
                        } else {
                            self.viewModel.switchSession(to: sessionKey)
                        }
                        self.newSessionName = ""
                        self.newAgentId = ""
                        self.isAgentSession = false
                        self.dismiss()
                    },
                    onCancel: {
                        self.newSessionName = ""
                        self.newAgentId = ""
                        self.isAgentSession = false
                    })
            }
        }
    }
}

private struct NewSessionSheet: View {
    @Binding var sessionName: String
    @Binding var agentId: String
    @Binding var isAgentSession: Bool
    let onCreate: (String) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var sessionKey: String {
        let name = self.sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.isAgentSession {
            let agent = self.agentId.trimmingCharacters(in: .whitespacesAndNewlines)
            if agent.isEmpty || name.isEmpty { return "" }
            return "agent:\(agent):\(name)"
        }
        return name
    }

    private var canCreate: Bool {
        !self.sessionKey.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Agent Session", isOn: self.$isAgentSession)
                } footer: {
                    Text("Agent sessions use configured agent settings (sandbox, tools, etc.)")
                }

                if self.isAgentSession {
                    Section("Agent") {
                        TextField("Agent ID (e.g. jarvis)", text: self.$agentId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Section("Session Name") {
                    TextField("Name (e.g. main)", text: self.$sessionName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if !self.sessionKey.isEmpty {
                    Section("Session Key") {
                        Text(self.sessionKey)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.onCancel()
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        self.onCreate(self.sessionKey)
                        self.dismiss()
                    }
                    .disabled(!self.canCreate)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct SessionRow: View {
    let session: ClawdbotChatSessionEntry
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: self.onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.session.displayName ?? self.session.key)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                    if let updatedAt = self.session.updatedAt, updatedAt > 0 {
                        Text(Date(timeIntervalSince1970: updatedAt / 1000).formatted(
                            date: .abbreviated,
                            time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if self.isActive {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
