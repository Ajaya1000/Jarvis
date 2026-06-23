import Foundation

struct ChatMessagePresentation: Identifiable, Hashable {
    let id: String
    let user: ChatParticipant
    let createdAt: Date
    let text: String
    let attachments: [ChatAttachment]
}

struct ChatParticipant: Hashable {
    let id: String
    let name: String
    let isCurrentUser: Bool

    static let currentUser = ChatParticipant(id: "currentUser", name: "You", isCurrentUser: true)
    static let assistant = ChatParticipant(id: "jarvis", name: "Jarvis", isCurrentUser: false)
}

struct ChatDraft: Hashable {
    var text: String
    var attachments: [ChatAttachment]
    var createdAt: Date
}

struct ChatAttachment: Identifiable, Hashable {
    enum Kind: Hashable {
        case image(Data)
        case audio(URL)
        case recording(URL, duration: TimeInterval)
    }

    let id: UUID
    let kind: Kind
    let name: String

    var iconName: String {
        switch kind {
        case .image:
            return "photo"
        case .audio:
            return "waveform"
        case .recording:
            return "mic"
        }
    }
}
