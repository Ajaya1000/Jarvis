import AVFoundation
import Observation
import PhotosUI
import SwiftUI
import Textual
import UniformTypeIdentifiers

struct LocalChatView: View {
    let messages: [ChatMessagePresentation]
    let isRequestInProgress: Bool
    var onSend: (ChatDraft) -> Void

    private let bottomAnchorID = "chat-bottom-anchor"

    @State private var draftText = ""
    @State private var attachments: [ChatAttachment] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showAudioImporter = false
    @State private var recorder = ChatAudioRecorder()
    @State private var isViewingLatestMessage = true
    @State private var shouldFollowLatestMessage = true
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    ForEach(messages) { message in
                        ChatMessageRow(message: message)
                            .id(message.id)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                            .listRowBackground(Color.clear)
                    }

                    if isRequestInProgress {
                        InProgressIndicatorView(visible: true)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                            .listRowBackground(Color.clear)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onAppear {
                            isViewingLatestMessage = true
                            shouldFollowLatestMessage = true
                        }
                        .onDisappear {
                            isViewingLatestMessage = false
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .contentShape(Rectangle())
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    shouldFollowLatestMessage = true
                    scrollToBottomWhenReady(proxy: proxy, animated: false)
                }
                .onTapGesture {
                    isInputFocused = false
                }
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        isInputFocused = false
                        if !isViewingLatestMessage {
                            shouldFollowLatestMessage = false
                        }
                    }
                )
                .onChange(of: messages) { oldMessages, newMessages in
                    updateFollowState(oldMessages: oldMessages, newMessages: newMessages)

                    if shouldFollowLatestMessage || isViewingLatestMessage {
                        scrollToBottomWhenReady(proxy: proxy)
                    }
                }
                .onChange(of: isRequestInProgress) { _, _ in
                    if shouldFollowLatestMessage || isViewingLatestMessage {
                        scrollToBottomWhenReady(proxy: proxy)
                    }
                }
            }

            ChatInputBar(
                text: $draftText,
                attachments: $attachments,
                selectedPhotos: $selectedPhotos,
                isInputFocused: $isInputFocused,
                isRecording: recorder.isRecording,
                recordingDuration: recorder.duration,
                isSendingDisabled: isRequestInProgress,
                onAudioTap: { showAudioImporter = true },
                onRecordTap: toggleRecording,
                onSend: sendDraft
            )
        }
        .fileImporter(
            isPresented: $showAudioImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                attachments.append(ChatAttachment(id: UUID(), kind: .audio(url), name: url.lastPathComponent))
            }
        }
        .onChange(of: selectedPhotos) { _, items in
            loadPhotos(items)
        }
    }

    private func sendDraft() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || !attachments.isEmpty else {
            return
        }

        onSend(ChatDraft(text: trimmedText, attachments: attachments, createdAt: .now))
        isViewingLatestMessage = true
        shouldFollowLatestMessage = true
        draftText = ""
        attachments.removeAll()
        selectedPhotos.removeAll()
    }

    private func toggleRecording() {
        Task {
            if recorder.isRecording {
                if let recording = await recorder.stop() {
                    attachments.append(recording)
                }
            } else {
                await recorder.start()
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            var imageAttachments: [ChatAttachment] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    imageAttachments.append(ChatAttachment(id: UUID(), kind: .image(data), name: "Image"))
                }
            }

            await MainActor.run {
                attachments.append(contentsOf: imageAttachments)
            }
        }
    }

    private func scrollToBottomWhenReady(proxy: ScrollViewProxy, animated: Bool = true) {
        Task { @MainActor in
            await Task.yield()
            scrollToBottom(proxy: proxy, animated: animated)
        }
    }

    private func updateFollowState(
        oldMessages: [ChatMessagePresentation],
        newMessages: [ChatMessagePresentation]
    ) {
        guard let latestMessage = newMessages.last else {
            shouldFollowLatestMessage = true
            return
        }

        let didInsertMessage = newMessages.count > oldMessages.count
        let didUpdateLatestMessage = oldMessages.last?.id == latestMessage.id
            && oldMessages.last?.text != latestMessage.text

        if latestMessage.user.isCurrentUser {
            shouldFollowLatestMessage = true
        } else if didInsertMessage {
            shouldFollowLatestMessage = true
        } else if didUpdateLatestMessage && isViewingLatestMessage {
            shouldFollowLatestMessage = true
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        let scroll = {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }

        if animated {
            withAnimation(.easeOut(duration: 0.2), scroll)
        } else {
            scroll()
        }
    }
}

private struct ChatMessageRow: View {
    let message: ChatMessagePresentation

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.user.isCurrentUser {
                Spacer(minLength: 44)
            } else {
                AssistantAvatar()
            }

            VStack(alignment: message.user.isCurrentUser ? .trailing : .leading, spacing: 6) {
                if !message.attachments.isEmpty {
                    AttachmentGrid(attachments: message.attachments)
                }

                if !message.text.isEmpty {
                    messageText
                }
            }
            .frame(maxWidth: 320, alignment: message.user.isCurrentUser ? .trailing : .leading)

            if message.user.isCurrentUser {
                Spacer(minLength: 0)
                    .frame(width: 2)
            } else {
                Spacer(minLength: 44)
            }
        }
    }

    @ViewBuilder
    private var messageText: some View {
        if message.user.isCurrentUser {
            Text(message.text)
                .font(.body)
                .foregroundStyle(.white)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            StructuredText(markdown: message.text)
                .textual
                .structuredTextStyle(.gitHub)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
    }
}

private struct AssistantAvatar: View {
    var body: some View {
        Image(systemName: "sparkles")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AttachmentGrid: View {
    let attachments: [ChatAttachment]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(attachments) { attachment in
                AttachmentPreview(attachment: attachment)
            }
        }
    }
}

private struct AttachmentPreview: View {
    let attachment: ChatAttachment

    var body: some View {
        switch attachment.kind {
        case let .image(data):
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        case .audio, .recording:
            Label(attachment.name, systemImage: attachment.iconName)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
    }
}

private struct ChatInputBar: View {
    @Binding var text: String
    @Binding var attachments: [ChatAttachment]
    @Binding var selectedPhotos: [PhotosPickerItem]
    var isInputFocused: FocusState<Bool>.Binding
    let isRecording: Bool
    let recordingDuration: TimeInterval
    let isSendingDisabled: Bool
    var onAudioTap: () -> Void
    var onRecordTap: () -> Void
    var onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            if !attachments.isEmpty || isRecording {
                AttachmentTray(
                    attachments: $attachments,
                    isRecording: isRecording,
                    recordingDuration: recordingDuration
                )
            }

            HStack(alignment: .bottom, spacing: 8) {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 4, matching: .images) {
                    Image(systemName: "photo")
                        .font(.body.weight(.semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add image")

                Button(action: onAudioTap) {
                    Image(systemName: "waveform")
                        .font(.body.weight(.semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add audio")

                Button(action: onRecordTap) {
                    Image(systemName: isRecording ? "stop.fill" : "mic")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isRecording ? .red : .primary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRecording ? "Stop recording" : "Record audio")

                TextField("Message", text: $text, axis: .vertical)
                    .focused(isInputFocused)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            canSend && !isSendingDisabled ? Color.accentColor : Color.secondary.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                }
                .disabled(!canSend || isSendingDisabled)
                .buttonStyle(.plain)
                .accessibilityLabel("Send")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }
}

private struct AttachmentTray: View {
    @Binding var attachments: [ChatAttachment]
    let isRecording: Bool
    let recordingDuration: TimeInterval

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if isRecording {
                    Label(recordingDuration.formattedRecordingDuration, systemImage: "record.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                ForEach(attachments) { attachment in
                    HStack(spacing: 6) {
                        Image(systemName: attachment.iconName)
                        Text(attachment.name)
                            .lineLimit(1)

                        Button {
                            attachments.removeAll { $0.id == attachment.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }
}

@MainActor
@Observable
private final class ChatAudioRecorder {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?

    var isRecording = false
    var duration: TimeInterval = 0

    func start() async {
        let allowed = await requestMicrophoneAccess()
        guard allowed else {
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("jarvis-recording-\(UUID().uuidString)")
                .appendingPathExtension("m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            recordingURL = url
            duration = 0
            isRecording = true
            startTimer()
        } catch {
            isRecording = false
            recorder = nil
            recordingURL = nil
        }
    }

    func stop() async -> ChatAttachment? {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false

        guard let recordingURL else {
            return nil
        }

        self.recordingURL = nil
        return ChatAttachment(
            id: UUID(),
            kind: .recording(recordingURL, duration: duration),
            name: "Recording \(duration.formattedRecordingDuration)"
        )
    }

    private func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.duration += 0.25
            }
        }
    }
}

private extension TimeInterval {
    var formattedRecordingDuration: String {
        let seconds = Int(self.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
