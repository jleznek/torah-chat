import SwiftUI

/// Root view — uses NavigationSplitView for the iPad two-column layout.
struct ContentView: View {
    @Environment(ChatViewModel.self) private var vm
    @State private var showSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } detail: {
            if let chat = vm.activeChat {
                ChatView(chat: chat)
            } else {
                WelcomeView()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

// MARK: - Welcome placeholder

private struct WelcomeView: View {
    @Environment(ChatViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Torah Chat")
                .font(.largeTitle.bold())
            Text("Ask any question about Jewish texts,\ncommentaries, and traditions.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Start a New Chat") {
                vm.newChat()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
