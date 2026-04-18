import SwiftUI

struct ChatView: View {
    @Environment(ChatViewModel.self) private var vm
    let chat: Chat
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Tool status banner
            if let status = vm.toolStatus {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(chat.messages) { msg in
                            MessageBubbleView(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(proxy: proxy, animated: false)
                }
                .onChange(of: chat.messages.count) {
                    scrollToBottom(proxy: proxy, animated: true)
                }
                .onChange(of: chat.messages.last?.content) {
                    scrollToBottom(proxy: proxy, animated: false)
                }
            }

            Divider()

            // Input bar
            inputBar
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about Jewish texts…", text: $inputText, axis: .vertical)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($inputFocused)
                .onSubmit {
                    // Submit on return key (not newline) when hardware keyboard is used
                    if !vm.isStreaming { sendMessage() }
                }

            if vm.isStreaming {
                Button {
                    vm.cancelStreaming()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.red)
                }
            } else {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Helpers

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await vm.send(text: text) }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastId = chat.messages.last?.id else { return }
        if animated {
            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
        } else {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
}
