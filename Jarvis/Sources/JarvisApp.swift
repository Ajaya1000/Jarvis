import SwiftUI
import SwiftData

@main
struct JarvisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [ConversationHistory.self, ChatMessageModel.self])
        }
    }
}
