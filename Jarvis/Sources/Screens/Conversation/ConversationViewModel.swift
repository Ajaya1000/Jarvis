//
//  ConversationViewModel.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import Observation
import ExyteChat

@MainActor
@Observable
class ConversationViewModel {
    var conversation: ConversationHistory
    var isRequestInProgress: Bool = false
    private let repository: ConversationRepository

    private var _conversationHelper: ConversationHelper?

    var messageList: [ChatMessage] {
        print(conversation.conversationList.map {$0.user.rawValue})
        return conversation.conversationList.map { chatMessageModel in
            ChatMessage(id: chatMessageModel.id.uuidString, user: chatMessageModel.user.messageUser, createdAt: chatMessageModel.createdAt, text: chatMessageModel.text)
        }
        .sorted(using: KeyPathComparator(\.createdAt))
    }

    init(conversation: ConversationHistory, repository: ConversationRepository) {
        self.conversation = conversation
        self.repository = repository
    }

    private func initializeConversationHelper() async throws -> ConversationHelper  {
        let conversationHelper = try await LMManager.shared.getNewConversationHelper(with: conversation)
        self._conversationHelper = conversationHelper

        return conversationHelper
    }

    func sendMessage(draft: DraftMessage) async {
        if isRequestInProgress {
            return
        }

        isRequestInProgress = true
        var assistantMessage: ChatMessageModel?

        do {
            let conversationHelper = try await initializeConversationHelper()

            conversation.conversationList.append(ChatMessageModel(user: ChatUser.user, createdAt: draft.createdAt, text: draft.text, conversation: conversation))
            conversation.lastUpdated = .now

            try repository.save()

            let stream = await conversationHelper.stream(with: .init(draft.text))

            for try await tokenChunk in stream {
                if assistantMessage == nil {
                    let newAssistantMessage = ChatMessageModel(user: ChatUser.assistant, text: "", conversation: conversation)
                    conversation.conversationList.append(newAssistantMessage)
                    assistantMessage = newAssistantMessage
                }

                assistantMessage?.text += tokenChunk.toString
                conversation.lastUpdated = .now
            }

            if assistantMessage != nil {
                try repository.save()
            }
        } catch {
            if assistantMessage != nil {
                try? repository.save()
            }
            print("Conversation didn't produce outout. Failed with error", error)
        }

        isRequestInProgress = false
    }

    private func makeMessage(with draft: DraftMessage, for user: User) async -> ChatMessage {
        let message = await ChatMessage.makeMessage(id: UUID().uuidString, user: user, draft: draft)
        return message
    }

    private func makeDraftMessage(with text: String) -> DraftMessage {
        return DraftMessage(text: text, medias: [], giphyMedia: nil, recording: nil, replyMessage: nil, createdAt: Date.now)
    }
}

extension ChatMessage {
    func appendNewText(with newText: String) -> ChatMessage {
        return .init(id: self.id, user: self.user, text: self.text + newText)
    }
}
