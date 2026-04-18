import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if isUser {
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .textSelection(.enabled)
                } else {
                    AutosizingMarkdownView(
                        markdown: message.content.isEmpty && message.isStreaming
                            ? "▋"
                            : message.content,
                        isStreaming: message.isStreaming
                    )
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            if !isUser { Spacer(minLength: 60) }
        }
    }
}
