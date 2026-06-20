//
//  LMManager.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import Foundation
import LiteRTLM

actor LMManager {
    static let shared: LMManager = {
        let lmManager = LMManager()
        return lmManager
    }()
    
    private var engine: Engine?
    private var _conversation: Conversation?
    
    private init() {
        
    }
    
    func getEngine() async throws -> Engine {
        if let engine {
            return engine
        }
        
        let config = try EngineConfig(modelPath: "path", backend: .gpu, cacheDir: NSTemporaryDirectory())
        
        let engine = Engine(engineConfig: config)
        
        try await engine.initialize()
        
        self.engine = engine
        
        return engine
    }
    
    var conversation: Conversation {
        get async throws {
            if let _conversation {
                return _conversation
            }
            
            let conversation = try await getEngine().createConversation()
            
            self._conversation = conversation
            
            return conversation
        }
    }
}
