import ClawdbotChatUI
import ClawdbotKit
import SwiftUI

// MARK: - Chat Home (Main Landing View)

struct ChatHomeView: View {
    @Environment(NodeAppModel.self) private var appModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSessions = false
    @State private var showingSettings = false
    @State private var showingVoice = false
    private let viewModel: ClawdbotChatViewModel
    private let userAccent: Color?
    private let themeMode: String

    init(viewModel: ClawdbotChatViewModel, userAccent: Color? = nil, themeMode: String = "system") {
        self.viewModel = viewModel
        self.userAccent = userAccent
        self.themeMode = themeMode
    }

    private var isDark: Bool { self.colorScheme == .dark }
    private var backgroundColor: Color { self.isDark ? .black : Color(.systemBackground) }
    private var foregroundColor: Color { self.isDark ? .white : .primary }
    private var glassOpacity: Double { self.isDark ? 0.1 : 0.08 }
    private var borderOpacity: Double { self.isDark ? 0.2 : 0.15 }

    var body: some View {
        VStack(spacing: 0) {
            ChatHomeHeader(
                showingSessions: self.$showingSessions,
                showingSettings: self.$showingSettings,
                showingVoice: self.$showingVoice,
                sessionName: self.activeSessionLabel,
                healthOK: self.viewModel.healthOK,
                userAccent: self.userAccent,
                isDark: self.isDark)

            ClawdbotChatView(
                viewModel: self.viewModel,
                showsSessionSwitcher: false,
                style: .liquidGlass,
                userAccent: self.userAccent)
        }
        .background(self.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: self.$showingSessions) {
            ChatSessionsSheet(viewModel: self.viewModel) { sessionKey in
                self.appModel.switchChatSession(to: sessionKey)
            }
        }
        .sheet(isPresented: self.$showingSettings) {
            SettingsTab()
        }
        .fullScreenCover(isPresented: self.$showingVoice) {
            VoicePage(userAccent: self.userAccent, isDark: self.isDark)
        }
    }

    private var activeSessionLabel: String {
        let key = self.viewModel.sessionKey
        if key.isEmpty { return "Chat" }
        return key
    }
}

// MARK: - Voice Page (Full Screen)

private struct VoicePage: View {
    @Environment(NodeAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let userAccent: Color?
    let isDark: Bool

    private var backgroundColor: Color { self.isDark ? .black : Color(.systemBackground) }
    private var foregroundColor: Color { self.isDark ? .white : .primary }

    var body: some View {
        ZStack {
            self.backgroundColor.ignoresSafeArea()

            // Talk orb centered
            TalkOrbOverlay()

            // Header with back button
            VStack {
                VoicePageHeader(
                    onBack: { self.dismiss() },
                    userAccent: self.userAccent,
                    isDark: self.isDark)
                Spacer()
            }
        }
        .onAppear {
            // Enable talk mode when entering voice page
            if !self.appModel.talkMode.isEnabled {
                self.appModel.setTalkEnabled(true)
            }
        }
        .onDisappear {
            // Disable talk mode when leaving voice page
            if self.appModel.talkMode.isEnabled {
                self.appModel.setTalkEnabled(false)
            }
        }
    }
}

// MARK: - Voice Page Header

private struct VoicePageHeader: View {
    let onBack: () -> Void
    let userAccent: Color?
    let isDark: Bool

    private var foregroundColor: Color { self.isDark ? .white : .primary }
    private var glassColor: Color { self.isDark ? .white : .black }
    private var glassOpacity: Double { self.isDark ? 0.1 : 0.06 }
    private var borderOpacity: Double { self.isDark ? 0.2 : 0.12 }

    var body: some View {
        HStack {
            // Back button (left, 36x36)
            Button(action: self.onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(self.foregroundColor)
            }
            .frame(width: 36, height: 36)
            .background(Circle().fill(self.glassColor.opacity(self.glassOpacity)))
            .overlay(Circle().strokeBorder(self.glassColor.opacity(self.borderOpacity)))

            Spacer()

            // Title pill
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(self.userAccent ?? self.foregroundColor)

                Text("Voice")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(self.foregroundColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(self.glassColor.opacity(self.borderOpacity)))

            Spacer()

            // Spacer for symmetry (36x36)
            Color.clear
                .frame(width: 36, height: 36)
        }
        .frame(height: 48)
        .padding(.horizontal, 14)
        .safeAreaPadding(.top, 4)
    }
}

// MARK: - Chat Home Header (Settings | Session Picker | Voice)

private struct ChatHomeHeader: View {
    @Binding var showingSessions: Bool
    @Binding var showingSettings: Bool
    @Binding var showingVoice: Bool
    let sessionName: String
    let healthOK: Bool
    let userAccent: Color?
    let isDark: Bool

    private var foregroundColor: Color { self.isDark ? .white : .primary }
    private var glassColor: Color { self.isDark ? .white : .black }
    private var glassOpacity: Double { self.isDark ? 0.1 : 0.06 }
    private var borderOpacity: Double { self.isDark ? 0.2 : 0.12 }
    private var secondaryOpacity: Double { self.isDark ? 0.6 : 0.5 }

    var body: some View {
        HStack {
            // Settings button (left, 36x36) - modern slider icon
            Button { self.showingSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(self.foregroundColor)
            }
            .frame(width: 36, height: 36)
            .background(Circle().fill(self.glassColor.opacity(self.glassOpacity)))
            .overlay(Circle().strokeBorder(self.glassColor.opacity(self.borderOpacity)))

            Spacer()

            // Center pill with avatar, title, dropdown, and health dot
            Button {
                self.showingSessions.toggle()
            } label: {
                HStack(spacing: 6) {
                    Text("🦞")
                        .font(.system(size: 12))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(self.glassColor.opacity(self.glassOpacity * 1.2)))

                    Text(self.sessionName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(self.foregroundColor)
                        .lineLimit(1)

                    Circle()
                        .fill(self.healthOK ? .green : .orange)
                        .frame(width: 6, height: 6)

                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(self.foregroundColor.opacity(self.secondaryOpacity))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().strokeBorder(self.glassColor.opacity(self.borderOpacity)))
            }

            Spacer()

            // Voice button (right, 36x36) - modern waveform icon
            Button { self.showingVoice = true } label: {
                Image(systemName: "waveform")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(self.foregroundColor)
            }
            .frame(width: 36, height: 36)
            .background(Circle().fill(self.glassColor.opacity(self.glassOpacity)))
            .overlay(Circle().strokeBorder(self.glassColor.opacity(self.borderOpacity)))
        }
        .frame(height: 48)
        .padding(.horizontal, 14)
        .safeAreaPadding(.top, 4)
    }
}

// MARK: - Chat Sheet (Legacy, for modal presentation)

struct ChatSheet: View {
    @Environment(NodeAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSessions = false
    private let viewModel: ClawdbotChatViewModel
    private let userAccent: Color?

    init(viewModel: ClawdbotChatViewModel, userAccent: Color? = nil) {
        self.viewModel = viewModel
        self.userAccent = userAccent
    }

    var body: some View {
        VStack(spacing: 0) {
            LiquidGlassHeader(
                showingSessions: self.$showingSessions,
                sessionName: self.activeSessionLabel,
                healthOK: self.viewModel.healthOK,
                onBack: { self.dismiss() })

            ClawdbotChatView(
                viewModel: self.viewModel,
                showsSessionSwitcher: false,
                style: .liquidGlass,
                userAccent: self.userAccent)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: self.$showingSessions) {
            ChatSessionsSheet(viewModel: self.viewModel) { sessionKey in
                self.appModel.switchChatSession(to: sessionKey)
            }
        }
    }

    private var activeSessionLabel: String {
        let key = self.viewModel.sessionKey
        if key.isEmpty { return "Chat" }
        return key
    }
}

// MARK: - Liquid Glass Header (for modal/sheet usage)

private struct LiquidGlassHeader: View {
    @Binding var showingSessions: Bool
    let sessionName: String
    let healthOK: Bool
    let onBack: () -> Void

    var body: some View {
        HStack {
            // Back button (32x32)
            Button(action: self.onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Spacer()

            // Center pill with avatar, title, and dropdown
            Button {
                self.showingSessions.toggle()
            } label: {
                HStack(spacing: 6) {
                    Text("🦞")
                        .font(.system(size: 12))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.12)))

                    Text(self.sessionName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().strokeBorder(.white.opacity(0.2)))
            }

            Spacer()

            // Health indicator (right side, 32x32 touch target)
            Circle()
                .fill(self.healthOK ? .green : .orange)
                .frame(width: 8, height: 8)
                .frame(width: 32, height: 32)
        }
        .frame(height: 48)
        .padding(.horizontal, 14)
    }
}
