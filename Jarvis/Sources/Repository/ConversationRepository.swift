//
//  ConversationRepository.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import SwiftData

class ConversationRepository {
    private let context: ModelContext
    
    private var continuation:
           AsyncStream<MessageChange>.Continuation?
    
    lazy var updates: AsyncStream<MessageChange> = AsyncStream { continuation in
        self.continuation = continuation
    }
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchConversations() throws -> [ConversationHistory] {
        var descriptor = FetchDescriptor<ConversationHistory>(
            sortBy: [
                .init(\.lastUpdated, order: .reverse)
            ]
        )
        
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }
    
    func addNew(conversation: ConversationHistory) throws {
        context.insert(conversation)
        try context.save()
        continuation?.yield(.init(type: .inserted))
    }
    
    func save() throws {
        try context.save()
        continuation?.yield(.init(type: .updated))
    }
}

struct MessageChange {
    enum ChangeType {
        case inserted
        case deleted
        case updated
    }
    
    let type: ChangeType
}
