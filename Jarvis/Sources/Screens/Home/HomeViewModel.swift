//
//  HomeViewModel.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import Observation

@Observable
class HomeViewModel {
    private let conversationRepository: ConversationRepository
    
    var isFetching: Bool = false
    var allConversation: [ConversationHistory] = []
    
    init(conversationRepository: ConversationRepository) {
        self.conversationRepository = conversationRepository
        
        startObservingUpdates()
    }
    
    private func startObservingUpdates() {
        Task {
            for await update in conversationRepository.updates {
                await fetchConversations()
            }
        }
    }
    
    @MainActor
    func fetchConversations() {
        do {
            allConversation = try conversationRepository.fetchConversations()
        } catch {
            print(error)
        }
    }
    
    func getNewConversation() throws -> ConversationHistory {
        let newConversation = ConversationHistory(title: "New Chat")
        
        try conversationRepository.addNew(conversation: newConversation)
        return newConversation
    }
}
