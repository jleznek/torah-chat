import SwiftUI

struct SidebarView: View {
    @Environment(ChatViewModel.self) private var vm

    var body: some View {
        List(selection: Binding(
            get: { vm.activeChat?.id },
            set: { id in
                if let id, let chat = vm.chats.first(where: { $0.id == id }) {
                    vm.selectChat(chat)
                }
            }
        )) {
            ForEach(vm.chats) { chat in
                NavigationLink(value: chat.id) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chat.title)
                            .lineLimit(1)
                            .font(.headline)
                        Text(chat.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        vm.deleteChat(chat)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.newChat()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
}
