//
//  ConversationHistory.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import SwiftData
import ExyteChat

@Model
class ConversationHistory {
    @Attribute(.unique)
    var id: UUID
    
    var startDate: Date
    
    var lastUpdated: Date
    
    var title: String
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessageModel.conversation)
    var conversationList: [ChatMessageModel]
    
    init(id: UUID = UUID(), startDate: Date = .now, lastUpdated: Date = .now, title: String, conversationList: [ChatMessageModel] = []) {
        self.id = id
        self.startDate = startDate
        self.lastUpdated = lastUpdated
        self.title = title
        self.conversationList = conversationList
    }
}

@Model
class ChatMessageModel {
    var id: UUID
    var user: ChatUser
    var text: String
    var conversation: ConversationHistory?
    var createdAt: Date
    
    init(id: UUID = UUID(), user: ChatUser, createdAt: Date = .now, text: String, conversation: ConversationHistory) {
        self.id = id
        self.user = user
        self.createdAt = createdAt
        self.text = text
        self.conversation = conversation
    }
}

enum ChatUser: String, Codable {
    case user
    case assistant
    
    var messageUser: User {
        switch self {
        case .user:
            return User(id: "currentUser", name: "You", avatarURL: nil, avatarCacheKey: nil, isCurrentUser: true)
        case .assistant:
            return User(id: "jarvis", name: "Jarvis", avatarURL: nil, type: .other)
        }
    }
}
