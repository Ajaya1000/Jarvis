import ExyteChat
import LiteRTLM
//
//  ConversationView.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import SwiftUI
import Textual

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
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )

                    StructuredText(markdown: (message.customData["preText"] as? String) ?? "")
                        .textual
                        .structuredTextStyle(.gitHub)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
        .betweenListAndInputViewBuilder {
            InProgressIndicatorView(visible: viewModel.isRequestInProgress)
        }

        .navigationTitle(viewModel.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.prepareConversationHelper()
        }
    }
}

struct InProgressIndicatorView: View {
    var visible: Bool
    @State private var isAnimating = false

    var body: some View {
        if visible {
            HStack {
                Spacer()
                
                HStack(spacing: 5) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 6, height: 6)
                            .offset(y: isAnimating ? -4 : 0)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                value: isAnimating
                            )
                    }
                }
                .frame(height: 18)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    InProgressIndicatorView(visible: true)
}
