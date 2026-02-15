import SwiftUI

struct MarkdownToolbar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 16) {
            Button {
                wrapSelection(prefix: "**", suffix: "**", placeholder: "bold text")
            } label: {
                Image(systemName: "bold")
                    .font(.body)
            }

            Button {
                wrapSelection(prefix: "*", suffix: "*", placeholder: "italic text")
            } label: {
                Image(systemName: "italic")
                    .font(.body)
            }

            Button {
                insertAtLineStart("- ", placeholder: "list item")
            } label: {
                Image(systemName: "list.bullet")
                    .font(.body)
            }

            Button {
                wrapSelection(prefix: "# ", suffix: "", placeholder: "heading")
            } label: {
                Image(systemName: "textformat.size")
                    .font(.body)
            }

            Button {
                wrapSelection(prefix: "`", suffix: "`", placeholder: "code")
            } label: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.body)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.bar)
        .buttonStyle(.plain)
    }

    private func wrapSelection(prefix: String, suffix: String, placeholder: String) {
        if text.isEmpty {
            text = "\(prefix)\(placeholder)\(suffix)"
        } else {
            text += "\(prefix)\(placeholder)\(suffix)"
        }
    }

    private func insertAtLineStart(_ prefix: String, placeholder: String) {
        if text.isEmpty || text.hasSuffix("\n") {
            text += "\(prefix)\(placeholder)"
        } else {
            text += "\n\(prefix)\(placeholder)"
        }
    }
}
