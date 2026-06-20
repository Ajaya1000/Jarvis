import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        Text("Hello, World!")
            .padding()
            .task {
                do {
                    let conversation = try await LMManager.shared.conversation
                    let response = try await conversation.sendMessage(.init("Hello World!"))
                    print("Response: ", response.toString)
                } catch {
                    print(error)
                }
            }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
