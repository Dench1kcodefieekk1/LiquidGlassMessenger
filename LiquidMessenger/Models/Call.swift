import Foundation

enum CallDirection: String, Codable, Equatable {
    case incoming
    case outgoing
    case missed
}

enum CallKind: String, Codable, Equatable {
    case audio
    case video
}

/// A call history entry. No VoIP is implemented; the shape mirrors what a
/// CallKit-backed service would produce so it can be swapped in later.
struct Call: Identifiable, Codable, Equatable {
    let id: String
    var contactName: String
    var gradientIndex: Int
    var direction: CallDirection
    var kind: CallKind
    var date: Date
    var duration: TimeInterval?

    init(id: String = UUID().uuidString,
         contactName: String,
         gradientIndex: Int = 0,
         direction: CallDirection,
         kind: CallKind = .audio,
         date: Date = .init(),
         duration: TimeInterval? = nil) {
        self.id = id
        self.contactName = contactName
        self.gradientIndex = gradientIndex
        self.direction = direction
        self.kind = kind
        self.date = date
        self.duration = duration
    }
}

/// Abstraction boundary for a future CallKit/VoIP integration.
protocol CallServiceProtocol {
    var calls: [Call] { get }
    func logCall(_ call: Call)
}

/// In-memory call history with seeded mock entries.
final class MockCallService: CallServiceProtocol {
    private(set) var calls: [Call]

    init() {
        let now = Date()
        let min: TimeInterval = 60
        let hour: TimeInterval = 3600
        calls = [
            Call(contactName: "Sofia Marchetti", gradientIndex: 1, direction: .outgoing, kind: .video, date: now.addingTimeInterval(-25 * min), duration: 14 * min + 12),
            Call(contactName: "Daniel Okafor", gradientIndex: 3, direction: .incoming, kind: .audio, date: now.addingTimeInterval(-2 * hour), duration: 3 * min + 41),
            Call(contactName: "Maya Lindqvist", gradientIndex: 2, direction: .missed, kind: .audio, date: now.addingTimeInterval(-5 * hour)),
            Call(contactName: "Liam O'Connor", gradientIndex: 4, direction: .outgoing, kind: .audio, date: now.addingTimeInterval(-8 * hour), duration: 47),
            Call(contactName: "Aiko Tanaka", gradientIndex: 5, direction: .incoming, kind: .video, date: now.addingTimeInterval(-26 * hour), duration: 22 * min + 5),
            Call(contactName: "Priya Sharma", gradientIndex: 6, direction: .missed, kind: .video, date: now.addingTimeInterval(-30 * hour)),
            Call(contactName: "Marco Rossi", gradientIndex: 0, direction: .outgoing, kind: .video, date: now.addingTimeInterval(-50 * hour), duration: 31 * min + 18),
            Call(contactName: "Elena Petrova", gradientIndex: 7, direction: .incoming, kind: .audio, date: now.addingTimeInterval(-70 * hour), duration: 8 * min + 3),
            Call(contactName: "Noah Fischer", gradientIndex: 8, direction: .outgoing, kind: .audio, date: now.addingTimeInterval(-96 * hour), duration: 1 * min + 22)
        ]
    }

    func logCall(_ call: Call) {
        calls.insert(call, at: 0)
    }
}
