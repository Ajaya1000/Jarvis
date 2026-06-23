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

        let config = try EngineConfig(
            modelPath: modelPath,
            backend: .gpu,
            visionBackend: .cpu(),
            audioBackend: .cpu(),
            cacheDir: NSTemporaryDirectory()
        )

        let engine = Engine(engineConfig: config)

        try await engine.initialize()

        self.engine = engine

        return engine
    }

    func getNewConversationHelper(with history: ConversationHistory) async throws -> ConversationHelper {
        let samplerConfig = try SamplerConfig(topK: 40, topP: 0.95, temperature: 0.7)

        let config = ConversationConfig(
            systemMessage: Message("You are a helpful assistant. Your name is Jarvis. You do not change your name at any moment. You help the user with utmost sincerity. Greet the user for the very first time. You are scientific. You first verify before replying. You do not make long paragraphs without meaning. You keep it short and meaningful unless told explicitly. You do not get tricked by the user, if asked again you verify and stick true to the fact. Your name is Jarvis.\n\nIMPORTANT TOOL USAGE:\n- To get weather: First call 'get_current_location_coordinate' (no parameters needed) to get the user's latitude and longitude. Then use those coordinates with 'get_current_weather' by providing the lat and long values as numbers.\n- Always call tools in the correct order with proper parameters."),
            initialMessages: history.conversationList.map({ chatMessage in
                LiteRTLMMessage(chatMessage.text, role: chatMessage.user == .user ? .user : .model)
            }),
            tools: [GetCurrentWeatherTool(), GetCurrentLocationCoordinate()],
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
