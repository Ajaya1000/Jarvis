//
//  HomeView.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    private let viewModel: HomeViewModel
    @State private var path: [ConversationHistory] = []
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Text("Home").font(.headline)
                AddNewButton(path: $path) {
                    try? viewModel.getNewConversation()
                }
                List(viewModel.allConversation) { item in
                    NavigationLink(value: item) {
                        HStack {
                            Text(item.title).font(.system(size: 12))
                            Spacer()
                            Text(item.startDate.formatted(date: .numeric, time: .shortened)).font(.system(size: 8, weight: .light))
                        }
                    }
                }
            }
            .navigationDestination(for: ConversationHistory.self, destination: { conversation in
                ConversationView(viewModel: .init(conversation: conversation, repository: .init(context: context)))
            })
        }
        .task {
            viewModel.fetchConversations()
        }
    }
}

struct AddNewButton: View {
    @Binding var path: [ConversationHistory]
    var getNewConversation: () -> ConversationHistory?
    var body: some View {
        Button(action: {
            if let newConvo = getNewConversation() {
                path.append(newConvo)
            }
        }) {
            HStack {
                Image(systemName: "square.and.pencil.circle.fill")
                Text("New Chat")
                Spacer()
            }
        }
    }
}
