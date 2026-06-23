//
//  ConversationHistory.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import SwiftData

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
    var userRawValue: String
    var text: String
    var conversation: ConversationHistory?
    var createdAt: Date

    init(id: UUID = UUID(), user: String, createdAt: Date = .now, text: String, conversation: ConversationHistory) {
        self.id = id
        self.userRawValue = user
        self.createdAt = createdAt
        self.text = text
        self.conversation = conversation
    }

    var user: ChatUser {
        return ChatUser(rawValue: userRawValue) ?? .user
    }
}

enum ChatUser: String, Codable {
    case user
    case assistant

    var messageUser: ChatParticipant {
        switch self {
        case .user:
            return .currentUser
        case .assistant:
            return .assistant
        }
    }
}
