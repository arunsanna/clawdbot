import SwiftUI
import Textual

public enum ChatMarkdownVariant: String, CaseIterable, Sendable {
    case standard
    case compact
}

@MainActor
struct ChatMarkdownRenderer: View {
    enum Context {
        case user
        case assistant
        case liquidGlassUser
        case liquidGlassAssistant
    }

    let text: String
    let context: Context
    let variant: ChatMarkdownVariant
    let font: Font
    let textColor: Color

    var body: some View {
        let processed = ChatMarkdownPreprocessor.preprocess(markdown: self.text)
        VStack(alignment: .leading, spacing: 10) {
            StructuredText(markdown: processed.cleaned)
                .modifier(ChatMarkdownStyle(
                    variant: self.variant,
                    context: self.context,
                    font: self.font,
                    textColor: self.textColor))

            if !processed.images.isEmpty {
                InlineImageList(images: processed.images)
            }
        }
    }
}

private struct ChatMarkdownStyle: ViewModifier {
    let variant: ChatMarkdownVariant
    let context: ChatMarkdownRenderer.Context
    let font: Font
    let textColor: Color
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { self.colorScheme == .dark }

    func body(content: Content) -> some View {
        Group {
            // Use .default style for liquid glass contexts to avoid gitHub's dark code backgrounds
            if self.variant == .compact || self.isLiquidGlass {
                content.textual.structuredTextStyle(.default)
            } else {
                content.textual.structuredTextStyle(.gitHub)
            }
        }
        .font(self.font)
        .foregroundStyle(self.textColor)
        .textual.inlineStyle(self.inlineStyle)
        .textual.textSelection(.enabled)
    }

    private var isLiquidGlass: Bool {
        self.context == .liquidGlassUser || self.context == .liquidGlassAssistant
    }

    private var inlineStyle: InlineStyle {
        let isUser = self.context == .user || self.context == .liquidGlassUser
        let linkColor: Color = isUser ? self.textColor : .accentColor
        let codeScale: CGFloat = self.variant == .compact ? 0.85 : 0.9

        // Terminal style for liquid glass: dark background, green/cyan text
        let (codeBackground, codeTextColor): (Color, Color?) = {
            switch self.context {
            case .liquidGlassAssistant, .liquidGlassUser:
                // Terminal style: always dark background with green text
                let terminalBg = Color(red: 0.1, green: 0.1, blue: 0.12)
                let terminalText = Color(red: 0.4, green: 0.9, blue: 0.4) // Terminal green
                return (terminalBg, terminalText)
            default:
                return (Color.white.opacity(0.1), nil)
            }
        }()

        if let textColor = codeTextColor {
            return InlineStyle()
                .code(.monospaced, .fontScale(codeScale), .backgroundColor(codeBackground), .foregroundColor(textColor))
                .link(.foregroundColor(linkColor))
        } else {
            return InlineStyle()
                .code(.monospaced, .fontScale(codeScale), .backgroundColor(codeBackground))
                .link(.foregroundColor(linkColor))
        }
    }
}

@MainActor
private struct InlineImageList: View {
    let images: [ChatMarkdownPreprocessor.InlineImage]

    var body: some View {
        ForEach(images, id: \.id) { item in
            if let img = item.image {
                OpenClawPlatformImageFactory.image(img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            } else {
                Text(item.label.isEmpty ? "Image" : item.label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
