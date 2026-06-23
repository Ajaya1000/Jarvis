//
//  ConversationViewModel.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import LiteRTLM
import Observation

@MainActor
@Observable
class ConversationViewModel {
    var conversation: ConversationHistory
    var isRequestInProgress: Bool = false
    private var transientAttachments: [UUID: [ChatAttachment]] = [:]
    private let repository: ConversationRepository

    private var _conversationHelper: ConversationHelper?
    private var conversationHelperTask: Task<ConversationHelper, Error>?

    var messageList: [ChatMessagePresentation] {
        let messageList =  conversation.conversationList.map { chatMessageModel in
            return ChatMessagePresentation(
                id: chatMessageModel.id.uuidString,
                user: chatMessageModel.user.messageUser,
                createdAt: chatMessageModel.createdAt,
                text: chatMessageModel.text,
                attachments: transientAttachments[chatMessageModel.id] ?? []
            )
        }
        .sorted(using: KeyPathComparator(\.createdAt))
        return messageList
    }
    
    init(conversation: ConversationHistory, repository: ConversationRepository) {
        self.conversation = conversation
        self.repository = repository
    }

    func prepareConversationHelper() {
        guard conversationHelperTask == nil else {
            return
        }

        let conversation = conversation
        conversationHelperTask = Task { @ConversationHelperPreparationActor in
            try await LMManager.shared.getNewConversationHelper(with: conversation)
        }
    }

    private func getConversationHelper() async throws -> ConversationHelper  {
        if let _conversationHelper {
            return _conversationHelper
        }

        prepareConversationHelper()

        guard let conversationHelperTask else {
            throw NSError(domain: "ConversationViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Conversation helper task was not created"])
        }

        do {
            let conversationHelper = try await conversationHelperTask.value
            self._conversationHelper = conversationHelper
            return conversationHelper
        } catch {
            self.conversationHelperTask = nil
            throw error
        }
    }

    func sendMessage(draft: ChatDraft) async {
        if isRequestInProgress {
            return
        }

        isRequestInProgress = true
        var assistantMessage: ChatMessageModel?
        let messageText = draft.text.isEmpty ? draft.attachmentSummary : draft.text

        do {
            let userMessage = ChatMessageModel(user: ChatUser.user.rawValue, createdAt: draft.createdAt, text: messageText, conversation: conversation)
            transientAttachments[userMessage.id] = draft.attachments
            conversation.conversationList.append(userMessage)
            conversation.lastUpdated = .now

            try repository.save()
            
            let conversationHelper = try await getConversationHelper()

            let stream = await conversationHelper.stream(with: draft.liteRTLMMessage(fallbackText: messageText))
            
            for try await tokenChunk in stream {
                if assistantMessage == nil {
                    let newAssistantMessage = ChatMessageModel(user: ChatUser.assistant.rawValue, text: "", conversation: conversation)
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
}

private extension ChatDraft {
    func liteRTLMMessage(fallbackText: String) -> LiteRTLMMessage {
        var contents: [Content] = [.text(fallbackText)]

        contents.append(contentsOf: attachments.compactMap { attachment in
            if case let .image(data) = attachment.kind {
                return .imageData(data)
            }

            return nil
        })

        return LiteRTLMMessage(contents: contents)
    }

    var attachmentSummary: String {
        let imageCount = attachments.filter {
            if case .image = $0.kind { return true }
            return false
        }.count
        let audioCount = attachments.count - imageCount

        switch (imageCount, audioCount) {
        case (1, 0):
            return "Shared an image."
        case let (count, 0):
            return "Shared \(count) images."
        case (0, 1):
            return "Shared an audio message."
        case let (0, count):
            return "Shared \(count) audio messages."
        default:
            return "Shared \(imageCount) images and \(audioCount) audio messages."
        }
    }
}
