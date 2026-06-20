//
//  ConversationView.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import SwiftUI
import LiteRTLM
import Textual
import ExyteChat

typealias LiteRTLMMessage = LiteRTLM.Message
typealias ChatMessage = ExyteChat.Message

struct ConversationView: View {
    @State var text: String = ""
    @State var viewModel: ConversationViewModel
    
    private var isTextValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ChatView(messages: viewModel.messageList) { draft in
            Task {
                await viewModel.sendMessage(draft: draft)
            }
        } messageBuilder: { params in
            let message = params.message
            if message.user.isCurrentUser {
                params.defaultMessageView()
            } else {
                HStack {
                    StructuredText(markdown: message.text).textual.structuredTextStyle(.gitHub)
                    Spacer()
                }
                .padding()
            }
        }
        .betweenListAndInputViewBuilder {
            InProgressIndicatorView(visible: viewModel.isRequestInProgress)
        }
    }
}

struct InProgressIndicatorView: View {
    var visible: Bool
    @State private var isAnimating = false
    
    var body: some View {
        if visible {
            HStack {
                Spacer() // Force alignment to the center
                
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(.systemGray2))
                            .frame(width: 7, height: 7)
                            .offset(y: isAnimating ? -5 : 0)
                        // Create a sequential wave effect using linear delay multipliers
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                value: isAnimating
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Spacer() // Force alignment to the center
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .onAppear {
                DispatchQueue.main.async {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
        } else {
            EmptyView()
        }
    }
}
