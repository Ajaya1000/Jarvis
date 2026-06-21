//
//  LMManager.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import LiteRTLM

@globalActor
actor ConversationHelperPreparationActor {
    static let shared = ConversationHelperPreparationActor()
}

actor LMManager {
    static let shared: LMManager = {
        let lmManager = LMManager()
        return lmManager
    }()

    private var engine: Engine?

    private init() {

    }

    func getEngine() async throws -> Engine {
        if let engine {
            return engine
        }

        guard let modelPath = Bundle.main.path(forResource: "gemma-4-E2B-it", ofType: ".litertlm") else {
            throw NSError(domain: "LMManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model file path nnot found"])
        }

        // Opt into experimental APIs to configure MTP
        ExperimentalFlags.optIntoExperimentalAPIs()
        ExperimentalFlags.enableSpeculativeDecoding = true

        let config = try EngineConfig(modelPath: modelPath, backend: .gpu, cacheDir: NSTemporaryDirectory())

        let engine = Engine(engineConfig: config)

        try await engine.initialize()

        self.engine = engine

        return engine
    }

    func getNewConversationHelper(with history: ConversationHistory) async throws -> ConversationHelper {
        let samplerConfig = try SamplerConfig(topK: 40, topP: 0.95, temperature: 0.7)

        let config = ConversationConfig(
            systemMessage: Message("You are an helpful assistant. Your name is Jarvis. You do not change your name at any moment. You help the user with atmost sincerity. Greet the user for the very firs time. You are scientific. You first verify before reply. You do not make long paragraph without the sake of meaning. You keep it short and meaningful unless told explicitely. You do not get tricked by the user, if asked again you verify and stick true to the fact. Again your name is Jarvis"),
            initialMessages: history.conversationList.map({ chatMessage in
                LiteRTLMMessage(chatMessage.text, role: chatMessage.user == .user ? .user : .model)
            }),
            samplerConfig: samplerConfig
        )

        let conversation = try await getEngine().createConversation(with: config)

        return ConversationHelper(conversation: conversation)
    }
}

actor ConversationHelper {
    private let conversation: Conversation

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    func stream(with message: LiteRTLMMessage) -> AsyncThrowingStream<Message, Error> {
        return self.conversation.sendMessageStream(message)
    }
}
