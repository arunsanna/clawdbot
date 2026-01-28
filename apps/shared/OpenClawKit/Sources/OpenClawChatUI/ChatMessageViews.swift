import ClawdbotKit
import Foundation
import SwiftUI

private enum ChatUIConstants {
    static let bubbleMaxWidth: CGFloat = 560
    static let bubbleCorner: CGFloat = 18
}

private struct ChatBubbleShape: InsettableShape {
    enum Tail {
        case left
        case right
        case none
    }

    let cornerRadius: CGFloat
    let tail: Tail
    var insetAmount: CGFloat = 0

    private let tailWidth: CGFloat = 7
    private let tailBaseHeight: CGFloat = 9

    func inset(by amount: CGFloat) -> ChatBubbleShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: self.insetAmount, dy: self.insetAmount)
        switch self.tail {
        case .left:
            return self.leftTailPath(in: rect, radius: self.cornerRadius)
        case .right:
            return self.rightTailPath(in: rect, radius: self.cornerRadius)
        case .none:
            return Path(roundedRect: rect, cornerRadius: self.cornerRadius)
        }
    }

    private func rightTailPath(in rect: CGRect, radius r: CGFloat) -> Path {
        var path = Path()
        let bubbleMinX = rect.minX
        let bubbleMaxX = rect.maxX - self.tailWidth
        let bubbleMinY = rect.minY
        let bubbleMaxY = rect.maxY

        let available = max(4, bubbleMaxY - bubbleMinY - 2 * r)
        let baseH = min(tailBaseHeight, available)
        let baseBottomY = bubbleMaxY - max(r * 0.45, 6)
        let baseTopY = baseBottomY - baseH
        let midY = (baseTopY + baseBottomY) / 2

        let baseTop = CGPoint(x: bubbleMaxX, y: baseTopY)
        let baseBottom = CGPoint(x: bubbleMaxX, y: baseBottomY)
        let tip = CGPoint(x: bubbleMaxX + self.tailWidth, y: midY)

        path.move(to: CGPoint(x: bubbleMinX + r, y: bubbleMinY))
        path.addLine(to: CGPoint(x: bubbleMaxX - r, y: bubbleMinY))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMaxX, y: bubbleMinY + r),
            control: CGPoint(x: bubbleMaxX, y: bubbleMinY))
        path.addLine(to: baseTop)
        path.addCurve(
            to: tip,
            control1: CGPoint(x: bubbleMaxX + self.tailWidth * 0.2, y: baseTopY + baseH * 0.05),
            control2: CGPoint(x: bubbleMaxX + self.tailWidth * 0.95, y: midY - baseH * 0.15))
        path.addCurve(
            to: baseBottom,
            control1: CGPoint(x: bubbleMaxX + self.tailWidth * 0.95, y: midY + baseH * 0.15),
            control2: CGPoint(x: bubbleMaxX + self.tailWidth * 0.2, y: baseBottomY - baseH * 0.05))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMaxX - r, y: bubbleMaxY),
            control: CGPoint(x: bubbleMaxX, y: bubbleMaxY))
        path.addLine(to: CGPoint(x: bubbleMinX + r, y: bubbleMaxY))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMinX, y: bubbleMaxY - r),
            control: CGPoint(x: bubbleMinX, y: bubbleMaxY))
        path.addLine(to: CGPoint(x: bubbleMinX, y: bubbleMinY + r))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMinX + r, y: bubbleMinY),
            control: CGPoint(x: bubbleMinX, y: bubbleMinY))

        return path
    }

    private func leftTailPath(in rect: CGRect, radius r: CGFloat) -> Path {
        var path = Path()
        let bubbleMinX = rect.minX + self.tailWidth
        let bubbleMaxX = rect.maxX
        let bubbleMinY = rect.minY
        let bubbleMaxY = rect.maxY

        let available = max(4, bubbleMaxY - bubbleMinY - 2 * r)
        let baseH = min(tailBaseHeight, available)
        let baseBottomY = bubbleMaxY - max(r * 0.45, 6)
        let baseTopY = baseBottomY - baseH
        let midY = (baseTopY + baseBottomY) / 2

        let baseTop = CGPoint(x: bubbleMinX, y: baseTopY)
        let baseBottom = CGPoint(x: bubbleMinX, y: baseBottomY)
        let tip = CGPoint(x: bubbleMinX - self.tailWidth, y: midY)

        path.move(to: CGPoint(x: bubbleMinX + r, y: bubbleMinY))
        path.addLine(to: CGPoint(x: bubbleMaxX - r, y: bubbleMinY))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMaxX, y: bubbleMinY + r),
            control: CGPoint(x: bubbleMaxX, y: bubbleMinY))
        path.addLine(to: CGPoint(x: bubbleMaxX, y: bubbleMaxY - r))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMaxX - r, y: bubbleMaxY),
            control: CGPoint(x: bubbleMaxX, y: bubbleMaxY))
        path.addLine(to: CGPoint(x: bubbleMinX + r, y: bubbleMaxY))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMinX, y: bubbleMaxY - r),
            control: CGPoint(x: bubbleMinX, y: bubbleMaxY))
        path.addLine(to: baseBottom)
        path.addCurve(
            to: tip,
            control1: CGPoint(x: bubbleMinX - self.tailWidth * 0.2, y: baseBottomY - baseH * 0.05),
            control2: CGPoint(x: bubbleMinX - self.tailWidth * 0.95, y: midY + baseH * 0.15))
        path.addCurve(
            to: baseTop,
            control1: CGPoint(x: bubbleMinX - self.tailWidth * 0.95, y: midY - baseH * 0.15),
            control2: CGPoint(x: bubbleMinX - self.tailWidth * 0.2, y: baseTopY + baseH * 0.05))
        path.addLine(to: CGPoint(x: bubbleMinX, y: bubbleMinY + r))
        path.addQuadCurve(
            to: CGPoint(x: bubbleMinX + r, y: bubbleMinY),
            control: CGPoint(x: bubbleMinX, y: bubbleMinY))

        return path
    }
}

@MainActor
struct ChatMessageBubble: View {
    let message: ClawdbotChatMessage
    let style: ClawdbotChatView.Style
    let markdownVariant: ChatMarkdownVariant
    let userAccent: Color?

    var body: some View {
        ChatMessageBody(
            message: self.message,
            isUser: self.isUser,
            style: self.style,
            markdownVariant: self.markdownVariant,
            userAccent: self.userAccent)
            .frame(maxWidth: ChatUIConstants.bubbleMaxWidth, alignment: self.isUser ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: self.isUser ? .trailing : .leading)
            .padding(.horizontal, 2)
    }

    private var isUser: Bool { self.message.role.lowercased() == "user" }
}

@MainActor
private struct ChatMessageBody: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: ClawdbotChatMessage
    let isUser: Bool
    let style: ClawdbotChatView.Style
    let markdownVariant: ChatMarkdownVariant
    let userAccent: Color?

    private var isDark: Bool { self.colorScheme == .dark }

    private var isLiquidGlass: Bool {
        #if os(macOS)
        false
        #else
        if case .liquidGlass = self.style { return true }
        return false
        #endif
    }

    private var textColor: Color {
        if self.isLiquidGlass {
            // Adaptive liquid glass: invert colors based on color scheme
            // Dark mode: user cyan, assistant white
            // Light mode: user accent/blue, assistant black
            if self.isUser {
                return self.userAccent ?? (self.isDark ? Color(red: 0.4, green: 0.85, blue: 1.0) : .blue)
            } else {
                return self.isDark ? .white : .black
            }
        }
        return self.isUser ? ClawdbotChatTheme.userText : ClawdbotChatTheme.assistantText
    }

    var body: some View {
        let text = self.primaryText

        VStack(alignment: .leading, spacing: 10) {
            if self.isToolResultMessage {
                if !text.isEmpty {
                    ToolResultCard(
                        title: self.toolResultTitle,
                        text: text,
                        isUser: self.isUser,
                        isLiquidGlass: self.isLiquidGlass)
                }
            } else if self.isUser {
                ChatMarkdownRenderer(
                    text: text,
                    context: self.isLiquidGlass ? .liquidGlassUser : .user,
                    variant: self.markdownVariant,
                    font: .system(size: 14),
                    textColor: self.textColor)
            } else {
                ChatAssistantTextBody(
                    text: text,
                    markdownVariant: self.markdownVariant,
                    textColor: self.textColor,
                    isLiquidGlass: self.isLiquidGlass)
            }

            if !self.inlineAttachments.isEmpty {
                ForEach(self.inlineAttachments.indices, id: \.self) { idx in
                    AttachmentRow(att: self.inlineAttachments[idx], isUser: self.isUser, isLiquidGlass: self.isLiquidGlass, userAccent: self.userAccent)
                }
            }

            if !self.toolCalls.isEmpty {
                ForEach(self.toolCalls.indices, id: \.self) { idx in
                    ToolCallCard(
                        content: self.toolCalls[idx],
                        isUser: self.isUser,
                        isLiquidGlass: self.isLiquidGlass)
                }
            }

            if !self.inlineToolResults.isEmpty {
                ForEach(self.inlineToolResults.indices, id: \.self) { idx in
                    let toolResult = self.inlineToolResults[idx]
                    let display = ToolDisplayRegistry.resolve(name: toolResult.name ?? "tool", args: nil)
                    ToolResultCard(
                        title: "\(display.emoji) \(display.title)",
                        text: toolResult.text ?? "",
                        isUser: self.isUser,
                        isLiquidGlass: self.isLiquidGlass)
                }
            }
        }
        .textSelection(.enabled)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .foregroundStyle(self.textColor)
        .background(self.bubbleBackground)
        .clipShape(self.bubbleShape)
        .overlay(self.bubbleBorder)
        .shadow(color: self.bubbleShadowColor, radius: self.bubbleShadowRadius, y: self.bubbleShadowYOffset)
        .padding(.leading, self.tailPaddingLeading)
        .padding(.trailing, self.tailPaddingTrailing)
    }

    private var primaryText: String {
        let parts = self.message.content.compactMap { content -> String? in
            let kind = (content.type ?? "text").lowercased()
            guard kind == "text" || kind.isEmpty else { return nil }
            return content.text
        }
        return parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var inlineAttachments: [ClawdbotChatMessageContent] {
        self.message.content.filter { content in
            switch content.type ?? "text" {
            case "file", "attachment":
                true
            default:
                false
            }
        }
    }

    private var toolCalls: [ClawdbotChatMessageContent] {
        self.message.content.filter { content in
            let kind = (content.type ?? "").lowercased()
            if ["toolcall", "tool_call", "tooluse", "tool_use"].contains(kind) {
                return true
            }
            return content.name != nil && content.arguments != nil
        }
    }

    private var inlineToolResults: [ClawdbotChatMessageContent] {
        self.message.content.filter { content in
            let kind = (content.type ?? "").lowercased()
            return kind == "toolresult" || kind == "tool_result"
        }
    }

    private var isToolResultMessage: Bool {
        let role = self.message.role.lowercased()
        return role == "toolresult" || role == "tool_result"
    }

    private var toolResultTitle: String {
        if let name = self.message.toolName, !name.isEmpty {
            let display = ToolDisplayRegistry.resolve(name: name, args: nil)
            return "\(display.emoji) \(display.title)"
        }
        let display = ToolDisplayRegistry.resolve(name: "tool", args: nil)
        return "\(display.emoji) \(display.title)"
    }

    private var bubbleFillColor: Color {
        if self.isLiquidGlass {
            // True liquid glass: completely transparent, no background
            return .clear
        }
        if self.isUser {
            return self.userAccent ?? ClawdbotChatTheme.userBubble
        }
        if self.style == .onboarding {
            return ClawdbotChatTheme.onboardingAssistantBubble
        }
        return ClawdbotChatTheme.assistantBubble
    }

    private var bubbleBackground: AnyShapeStyle {
        AnyShapeStyle(self.bubbleFillColor)
    }

    private var bubbleBorderColor: Color {
        if self.isLiquidGlass {
            // True liquid glass: no borders
            return .clear
        }
        if self.isUser {
            return Color.white.opacity(0.12)
        }
        if self.style == .onboarding {
            return ClawdbotChatTheme.onboardingAssistantBorder
        }
        return Color.white.opacity(0.08)
    }

    private var bubbleBorderWidth: CGFloat {
        if self.isLiquidGlass {
            // True liquid glass: no borders
            return 0
        }
        if self.isUser { return 0.5 }
        if self.style == .onboarding { return 0.8 }
        return 1
    }

    private var bubbleBorder: some View {
        self.bubbleShape.strokeBorder(self.bubbleBorderColor, lineWidth: self.bubbleBorderWidth)
    }

    private var bubbleShape: ChatBubbleShape {
        ChatBubbleShape(cornerRadius: ChatUIConstants.bubbleCorner, tail: self.bubbleTail)
    }

    private var bubbleTail: ChatBubbleShape.Tail {
        guard self.style == .onboarding else { return .none }
        return self.isUser ? .right : .left
    }

    private var tailPaddingLeading: CGFloat {
        self.style == .onboarding && !self.isUser ? 8 : 0
    }

    private var tailPaddingTrailing: CGFloat {
        self.style == .onboarding && self.isUser ? 8 : 0
    }

    private var bubbleShadowColor: Color {
        self.style == .onboarding && !self.isUser ? Color.black.opacity(0.28) : .clear
    }

    private var bubbleShadowRadius: CGFloat {
        self.style == .onboarding && !self.isUser ? 6 : 0
    }

    private var bubbleShadowYOffset: CGFloat {
        self.style == .onboarding && !self.isUser ? 2 : 0
    }
}

private struct AttachmentRow: View {
    let att: ClawdbotChatMessageContent
    let isUser: Bool
    var isLiquidGlass: Bool = false
    var userAccent: Color?
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { self.colorScheme == .dark }

    private var textColor: Color {
        if self.isLiquidGlass {
            // Adaptive liquid glass
            if self.isUser {
                return self.userAccent ?? (self.isDark ? Color(red: 0.4, green: 0.85, blue: 1.0) : .blue)
            }
            return self.isDark ? .white : .black
        }
        return self.isUser ? ClawdbotChatTheme.userText : ClawdbotChatTheme.assistantText
    }

    private var cardBackground: Color {
        if self.isLiquidGlass {
            return self.isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
        }
        return self.isUser ? Color.white.opacity(0.2) : Color.black.opacity(0.04)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "paperclip")
                .foregroundStyle(self.textColor)
            Text(self.att.fileName ?? "Attachment")
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(self.textColor)
            Spacer()
        }
        .padding(10)
        .background(self.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ToolCallCard: View {
    let content: ClawdbotChatMessageContent
    let isUser: Bool
    var isLiquidGlass: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { self.colorScheme == .dark }

    private var cardFill: AnyShapeStyle {
        if self.isLiquidGlass {
            return AnyShapeStyle(self.isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
        }
        return ClawdbotChatTheme.subtleCard
    }

    private var cardStroke: Color {
        if self.isLiquidGlass {
            return self.isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)
        }
        return Color.white.opacity(0.08)
    }

    private var textColor: Color {
        self.isLiquidGlass ? (self.isDark ? .white : .black) : .primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(self.toolName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(self.textColor)
                Spacer(minLength: 0)
            }

            if let summary = self.summary, !summary.isEmpty {
                Text(summary)
                    .font(.footnote.monospaced())
                    .foregroundStyle(self.isLiquidGlass ? (self.isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)) : .secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(self.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(self.cardStroke, lineWidth: 1)))
    }

    private var toolName: String {
        "\(self.display.emoji) \(self.display.title)"
    }

    private var summary: String? {
        self.display.detailLine
    }

    private var display: ToolDisplaySummary {
        ToolDisplayRegistry.resolve(name: self.content.name ?? "tool", args: self.content.arguments)
    }
}

private struct ToolResultCard: View {
    let title: String
    let text: String
    let isUser: Bool
    var isLiquidGlass: Bool = false
    @State private var expanded = false
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { self.colorScheme == .dark }

    private var textColor: Color {
        if self.isLiquidGlass {
            return self.isDark ? .white : .black
        }
        return self.isUser ? ClawdbotChatTheme.userText : ClawdbotChatTheme.assistantText
    }

    private var cardFill: AnyShapeStyle {
        if self.isLiquidGlass {
            return AnyShapeStyle(self.isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
        }
        return ClawdbotChatTheme.subtleCard
    }

    private var cardStroke: Color {
        if self.isLiquidGlass {
            return self.isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)
        }
        return Color.white.opacity(0.08)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(self.title)
                    .font(.footnote.weight(.semibold))
                Spacer(minLength: 0)
            }

            Text(self.displayText)
                .font(.footnote.monospaced())
                .foregroundStyle(self.textColor)
                .lineLimit(self.expanded ? nil : Self.previewLineLimit)

            if self.shouldShowToggle {
                Button(self.expanded ? "Show less" : "Show full output") {
                    self.expanded.toggle()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(self.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(self.cardStroke, lineWidth: 1)))
    }

    private static let previewLineLimit = 8

    private var lines: [Substring] {
        self.text.components(separatedBy: .newlines).map { Substring($0) }
    }

    private var displayText: String {
        guard !self.expanded, self.lines.count > Self.previewLineLimit else { return self.text }
        return self.lines.prefix(Self.previewLineLimit).joined(separator: "\n") + "\n…"
    }

    private var shouldShowToggle: Bool {
        self.lines.count > Self.previewLineLimit
    }
}

@MainActor
struct ChatTypingIndicatorBubble: View {
    let style: ClawdbotChatView.Style

    private var isLiquidGlass: Bool {
        #if os(macOS)
        false
        #else
        if case .liquidGlass = self.style { return true }
        return false
        #endif
    }

    var body: some View {
        #if os(macOS)
        self.standardBody
        #else
        if self.isLiquidGlass {
            // Liquid glass: just dots, no bubble
            TypingDots(isLiquidGlass: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        } else {
            self.standardBody
        }
        #endif
    }

    private var standardBody: some View {
        HStack(spacing: 10) {
            TypingDots(isLiquidGlass: false)
            if self.style == .standard {
                Text("Clawd is thinking…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, self.style == .standard ? 12 : 10)
        .padding(.horizontal, self.style == .standard ? 12 : 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ClawdbotChatTheme.assistantBubble))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .frame(maxWidth: ChatUIConstants.bubbleMaxWidth, alignment: .leading)
        .focusable(false)
    }
}

extension ChatTypingIndicatorBubble: @MainActor Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.style == rhs.style
    }
}

@MainActor
struct ChatStreamingAssistantBubble: View {
    let text: String
    let markdownVariant: ChatMarkdownVariant
    var style: ClawdbotChatView.Style = .standard

    private var isLiquidGlass: Bool {
        #if os(macOS)
        false
        #else
        if case .liquidGlass = self.style { return true }
        return false
        #endif
    }

    private var bubbleFill: Color {
        #if os(macOS)
        ClawdbotChatTheme.assistantBubble
        #else
        if case .liquidGlass = self.style {
            return .clear // True liquid glass: no background
        }
        return ClawdbotChatTheme.assistantBubble
        #endif
    }

    private var bubbleStroke: Color {
        #if os(macOS)
        Color.white.opacity(0.08)
        #else
        if case .liquidGlass = self.style {
            return .clear // True liquid glass: no border
        }
        return Color.white.opacity(0.08)
        #endif
    }

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { self.colorScheme == .dark }

    private var textColor: Color {
        #if os(macOS)
        ClawdbotChatTheme.assistantText
        #else
        if case .liquidGlass = self.style {
            return self.isDark ? .white : .black // Adaptive liquid glass
        }
        return ClawdbotChatTheme.assistantText
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChatAssistantTextBody(
                text: self.text,
                markdownVariant: self.markdownVariant,
                textColor: self.textColor,
                isLiquidGlass: self.isLiquidGlass)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(self.bubbleFill))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(self.bubbleStroke, lineWidth: 1))
        .frame(maxWidth: ChatUIConstants.bubbleMaxWidth, alignment: .leading)
        .focusable(false)
    }
}

@MainActor
struct ChatPendingToolsBubble: View {
    let toolCalls: [ClawdbotChatPendingToolCall]
    var style: ClawdbotChatView.Style = .standard
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { self.colorScheme == .dark }

    private var isLiquidGlass: Bool {
        #if os(macOS)
        false
        #else
        if case .liquidGlass = self.style { return true }
        return false
        #endif
    }

    private var bubbleFill: Color {
        #if os(macOS)
        ClawdbotChatTheme.assistantBubble
        #else
        if case .liquidGlass = self.style {
            return .clear // Liquid glass: no background
        }
        return ClawdbotChatTheme.assistantBubble
        #endif
    }

    private var bubbleStroke: Color {
        #if os(macOS)
        Color.white.opacity(0.08)
        #else
        if case .liquidGlass = self.style {
            return .clear // Liquid glass: no border
        }
        return Color.white.opacity(0.08)
        #endif
    }

    private var textColor: Color {
        #if os(macOS)
        ClawdbotChatTheme.assistantText
        #else
        if case .liquidGlass = self.style {
            return self.isDark ? .white : .black // Adaptive liquid glass
        }
        return ClawdbotChatTheme.assistantText
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Running tools…", systemImage: "hammer")
                .font(.caption)
                .foregroundStyle(self.textColor.opacity(0.6))

            ForEach(self.toolCalls) { call in
                let display = ToolDisplayRegistry.resolve(name: call.name, args: call.args)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(display.emoji) \(display.label)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(self.textColor)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        ProgressView().controlSize(.mini)
                            .tint(self.isLiquidGlass ? .white : nil)
                    }
                    if let detail = display.detailLine, !detail.isEmpty {
                        Text(detail)
                            .font(.caption.monospaced())
                            .foregroundStyle(self.textColor.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                .padding(10)
                .background(self.isLiquidGlass ? (self.isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)) : self.textColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(self.bubbleFill))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(self.bubbleStroke, lineWidth: 1))
        .frame(maxWidth: ChatUIConstants.bubbleMaxWidth, alignment: .leading)
        .focusable(false)
    }
}

extension ChatPendingToolsBubble: @MainActor Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.toolCalls == rhs.toolCalls && lhs.style == rhs.style
    }
}

@MainActor
private struct TypingDots: View {
    var isLiquidGlass: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var visibleCount: Int = 1
    @State private var timerTask: Task<Void, Never>?

    private var isDark: Bool { self.colorScheme == .dark }

    private var dotColor: Color {
        if self.isLiquidGlass {
            return self.isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.5)
        }
        return Color.secondary.opacity(0.6)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { idx in
                Circle()
                    .fill(self.dotColor)
                    .frame(width: 6, height: 6)
                    .opacity(idx < self.visibleCount ? 1.0 : 0.0)
            }
        }
        .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.15), value: self.visibleCount)
        .onAppear { self.startAnimation() }
        .onDisappear { self.stopAnimation() }
        .onChange(of: self.scenePhase) { _, phase in
            if phase == .active {
                self.startAnimation()
            } else {
                self.stopAnimation()
            }
        }
    }

    private func startAnimation() {
        guard !self.reduceMotion else {
            self.visibleCount = 3
            return
        }
        self.stopAnimation()
        self.timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s per step
                if Task.isCancelled { break }
                await MainActor.run {
                    self.visibleCount = (self.visibleCount % 3) + 1
                }
            }
        }
    }

    private func stopAnimation() {
        self.timerTask?.cancel()
        self.timerTask = nil
    }
}

private struct ChatAssistantTextBody: View {
    let text: String
    let markdownVariant: ChatMarkdownVariant
    var textColor: Color = ClawdbotChatTheme.assistantText
    var isLiquidGlass: Bool = false

    var body: some View {
        let segments = AssistantTextParser.segments(from: self.text)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(segments) { segment in
                let font = segment.kind == .thinking ? Font.system(size: 14).italic() : Font.system(size: 14)
                ChatMarkdownRenderer(
                    text: segment.text,
                    context: self.isLiquidGlass ? .liquidGlassAssistant : .assistant,
                    variant: self.markdownVariant,
                    font: font,
                    textColor: self.textColor)
            }
        }
    }
}
