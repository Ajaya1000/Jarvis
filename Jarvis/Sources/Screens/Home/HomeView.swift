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
            List {
                Section {
                    AddNewButton(path: $path) {
                        try? viewModel.getNewConversation()
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Conversations") {
                    if viewModel.allConversation.isEmpty {
                        ContentUnavailableView(
                            "No Conversations",
                            systemImage: "message",
                            description: Text("Start a new chat when you are ready.")
                        )
                        .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
                    } else {
                        ForEach(viewModel.allConversation) { item in
                            NavigationLink(value: item) {
                                ConversationRow(conversation: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Jarvis")
            .listStyle(.insetGrouped)
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
            Label {
                Text("New Chat")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ConversationRow: View {
    let conversation: ConversationHistory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                Text(conversation.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
