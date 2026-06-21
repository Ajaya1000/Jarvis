import SwiftUI

public struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    public init() {}

    public var body: some View {
        HomeView(viewModel: .init(conversationRepository: .init(context: context)))
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
