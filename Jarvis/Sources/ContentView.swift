import SwiftUI

public struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    public init() {}

    public var body: some View {
        VStack {
            Text("Jarvis")
            // Navigation needs to be added
//            ConversationView(viewModel: .init())
            HomeView(viewModel: .init(conversationRepository: .init(context: context)))
        }
        .padding()
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
