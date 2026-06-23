import LiteRTLM
//
//  ConversationView.swift
//  Jarvis
//
//  Created by Ajaya Mati on 20/06/26.
//
import SwiftUI

typealias LiteRTLMMessage = LiteRTLM.Message

struct ConversationView: View {
    @State var viewModel: ConversationViewModel

    var body: some View {
        LocalChatView(messages: viewModel.messageList, isRequestInProgress: viewModel.isRequestInProgress) { draft in
            Task {
                await viewModel.sendMessage(draft: draft)
            }
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
