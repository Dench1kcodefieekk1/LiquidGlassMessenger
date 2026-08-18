import Foundation

/// Deterministic, realistic seed data. All timestamps are relative to "now"
/// so the demo always looks fresh.
enum MockData {

    static let meID = "me"

    static let defaultProfile = User(
        id: meID,
        name: "Alex Rivera",
        username: "alex.rivera",
        bio: "Building calm software. Coffee, cycling, analog cameras.",
        isOnline: true,
        lastSeen: Date(),
        gradientIndex: 0
    )

    // MARK: Replies used by the incoming-message simulator

    static let cannedReplies: [String] = [
        "Sounds good, let's do it.",
        "Haha, exactly!",
        "Give me five minutes and I'll get back to you.",
        "I was just thinking the same thing.",
        "Perfect, thanks a lot.",
        "Can you send me the details later today?",
        "Honestly, that sounds amazing.",
        "Let me check and confirm.",
        "On my way now.",
        "Sure, works for me."
    ]

    // MARK: Helpers

    private static func date(daysAgo: Double = 0, hoursAgo: Double = 0, minutesAgo: Double = 0) -> Date {
        Date().addingTimeInterval(-(daysAgo * 86_400 + hoursAgo * 3_600 + minutesAgo * 60))
    }

    private static func msg(_ senderID: String,
                            _ incoming: Bool,
                            _ text: String,
                            minutesAgo: Double,
                            kind: MessageKind = .text,
                            attachment: MessageAttachment? = nil,
                            status: MessageStatus = .read,
                            reactions: [MessageReaction] = []) -> Message {
        Message(senderID: senderID,
                incoming: incoming,
                kind: kind,
                text: text,
                attachment: attachment,
                date: date(minutesAgo: minutesAgo),
                status: status,
                reactions: reactions)
    }

    // MARK: Chats

    static func makeChats() -> [Chat] {
        var chats: [Chat] = []

        func add(_ id: String, _ name: String, _ username: String, gradient: Int, online: Bool,
                 pinned: Bool = false, muted: Bool = false, archived: Bool = false,
                 unread: Int = 0, messages: [Message]) {
            let peer = User(id: id,
                            name: name,
                            username: username,
                            bio: "",
                            isOnline: online,
                            lastSeen: date(hoursAgo: Double(gradient) + 1),
                            gradientIndex: gradient)
            chats.append(Chat(id: id,
                              peer: peer,
                              lastMessage: messages.last,
                              unreadCount: unread,
                              isPinned: pinned,
                              isMuted: muted,
                              isArchived: archived))
            MockMessagesStore.seed(chatID: id, messages: messages)
        }

        add("u_sofia", "Sofia Marchetti", "sofia.m", gradient: 1, online: true, pinned: true, unread: 2, messages: [
            msg("u_sofia", true, "Hey! Did you see the northern lights photos?", minutesAgo: 190),
            msg(meID, false, "Not yet, send them over!", minutesAgo: 186),
            msg("u_sofia", true, "", minutesAgo: 175, kind: .image, attachment: .init(kind: .image, name: "aurora_kirkenes.jpg")),
            msg(meID, false, "These are unreal. Where exactly were you?", minutesAgo: 170, reactions: [.init(emoji: "❤️", isFromMe: false, count: 1)]),
            msg("u_sofia", true, "Kirkenes, right at the border. Totally worth the -20 degrees.", minutesAgo: 42),
            msg("u_sofia", true, "You should come next winter, I'll plan everything.", minutesAgo: 40)
        ])

        add("u_daniel", "Daniel Okafor", "d.okafor", gradient: 3, online: true, pinned: true, messages: [
            msg("u_daniel", true, "The staging deploy finished, all green.", minutesAgo: 260),
            msg(meID, false, "Awesome. Did the migration scripts run cleanly?", minutesAgo: 255),
            msg("u_daniel", true, "Yep, zero data loss. Took 4 minutes.", minutesAgo: 250),
            msg(meID, false, "That's brilliant. Let's ship to prod on Thursday then.", minutesAgo: 240),
            msg("u_daniel", true, "Thursday works. I'll prep the rollback plan just in case.", minutesAgo: 55)
        ])

        add("u_maya", "Maya Lindqvist", "maya.l", gradient: 2, online: false, unread: 1, messages: [
            msg("u_maya", true, "Finished the first draft of the cover!", minutesAgo: 1_500),
            msg(meID, false, "Can't wait to see it.", minutesAgo: 1_490),
            msg("u_maya", true, "", minutesAgo: 300, kind: .image, attachment: .init(kind: .image, name: "cover_draft_v3.png")),
            msg("u_maya", true, "Typography still needs work but the mood is there.", minutesAgo: 298)
        ])

        add("u_liam", "Liam O'Connor", "liam.oc", gradient: 4, online: true, messages: [
            msg(meID, false, "Still up for squash on Saturday?", minutesAgo: 480),
            msg("u_liam", true, "Absolutely. 10am at the usual place?", minutesAgo: 470),
            msg(meID, false, "Perfect. I'll book court 3.", minutesAgo: 465),
            msg("u_liam", true, "You're on. Prepare to lose this time.", minutesAgo: 460)
        ])

        add("u_aiko", "Aiko Tanaka", "aiko.t", gradient: 5, online: false, muted: true, messages: [
            msg("u_aiko", true, "", minutesAgo: 1_600, kind: .voice, attachment: .init(kind: .voice, name: "voice_note.m4a", duration: 42)),
            msg(meID, false, "Listening now — the idea is great, let's discuss tomorrow.", minutesAgo: 1_580),
            msg("u_aiko", true, "Great! I'll write up a one-pager.", minutesAgo: 700)
        ])

        add("u_priya", "Priya Sharma", "priya.s", gradient: 6, online: true, unread: 3, messages: [
            msg("u_priya", true, "The workshop recording is ready.", minutesAgo: 130),
            msg("u_priya", true, "", minutesAgo: 128, kind: .video, attachment: .init(kind: .video, name: "workshop_recording.mp4", duration: 3_720)),
            msg("u_priya", true, "Slides are in the shared drive as well.", minutesAgo: 126)
        ])

        add("u_marco", "Marco Rossi", "marco.rossi", gradient: 0, online: false, messages: [
            msg("u_marco", true, "Reservation confirmed for Friday 8pm.", minutesAgo: 2_100),
            msg(meID, false, "Great, the terrace if possible?", minutesAgo: 2_090),
            msg("u_marco", true, "Done. Table 12, terrace, view of the canal.", minutesAgo: 2_080),
            msg(meID, false, "You're a legend.", minutesAgo: 2_070, reactions: [.init(emoji: "👍", isFromMe: false, count: 1)])
        ])

        add("u_elena", "Elena Petrova", "elena.p", gradient: 7, online: false, messages: [
            msg("u_elena", true, "", minutesAgo: 3_000, kind: .file, attachment: .init(kind: .file, name: "Q3-report-final.pdf")),
            msg(meID, false, "Received, I'll review it tonight.", minutesAgo: 2_990),
            msg("u_elena", true, "No rush, Monday is fine.", minutesAgo: 2_980)
        ])

        add("u_noah", "Noah Fischer", "noah.f", gradient: 8, online: true, messages: [
            msg("u_noah", true, "Check the shared location — that's the trailhead.", minutesAgo: 4_200),
            msg("u_noah", true, "", minutesAgo: 4_199, kind: .location, attachment: .init(kind: .location, name: "Schreckensee Trailhead")),
            msg(meID, false, "Got it. Starting at 7am sharp?", minutesAgo: 4_180),
            msg("u_noah", true, "7am. Bring the good boots, it's muddy after the rain.", minutesAgo: 4_170)
        ])

        add("u_clara", "Clara Dubois", "clara.d", gradient: 9, online: false, archived: true, messages: [
            msg("u_clara", true, "Thanks again for the recommendation!", minutesAgo: 12_000),
            msg(meID, false, "Anytime — enjoy the book.", minutesAgo: 11_990)
        ])

        add("u_tomas", "Tomás Herrera", "tomas.h", gradient: 1, online: false, messages: [
            msg("u_tomas", true, "The prototype demo went really well.", minutesAgo: 5_000),
            msg(meID, false, "Congrats! Investors happy?", minutesAgo: 4_990),
            msg("u_tomas", true, "Two follow-up meetings booked for next week.", minutesAgo: 4_980)
        ])

        add("u_hana", "Hana Kobayashi", "hana.k", gradient: 2, online: true, messages: [
            msg("u_hana", true, "Sent you the playlist for the road trip.", minutesAgo: 6_200),
            msg(meID, false, "Excellent taste as always.", minutesAgo: 6_190)
        ])

        add("u_viktor", "Viktor Novak", "viktor.n", gradient: 3, online: false, muted: true, messages: [
            msg("u_viktor", true, "Newsletter is out — you're mentioned on page 2.", minutesAgo: 7_500),
            msg(meID, false, "Honored! Sharing it now.", minutesAgo: 7_490)
        ])

        add("u_amara", "Amara Diallo", "amara.d", gradient: 4, online: true, messages: [
            msg("u_amara", true, "Flight lands 14:35, can you pick me up?", minutesAgo: 8_000),
            msg(meID, false, "Of course, I'll be at arrivals.", minutesAgo: 7_990),
            msg("u_amara", true, "You're the best.", minutesAgo: 7_980, reactions: [.init(emoji: "✨", isFromMe: true, count: 1)])
        ])

        add("u_jonas", "Jonas Weber", "jonas.w", gradient: 5, online: false, messages: [
            msg("u_jonas", true, "", minutesAgo: 9_000, kind: .image, attachment: .init(kind: .image, name: "workshop_setup.jpg")),
            msg(meID, false, "The new bench looks great.", minutesAgo: 8_990)
        ])

        add("u_ingrid", "Ingrid Solberg", "ingrid.s", gradient: 6, online: false, messages: [
            msg("u_ingrid", true, "Recipe sent — don't skip the cardamom.", minutesAgo: 10_000),
            msg(meID, false, "Would never.", minutesAgo: 9_990)
        ])

        add("u_rafael", "Rafael Costa", "rafa.c", gradient: 7, online: true, unread: 1, messages: [
            msg("u_rafael", true, "Match highlights are up on the club page.", minutesAgo: 35)
        ])

        add("u_zoe", "Zoë Williams", "zoe.w", gradient: 8, online: false, messages: [
            msg("u_zoe", true, "Gallery opening moved to 19:00, doors close at 21.", minutesAgo: 13_000),
            msg(meID, false, "Noted, see you there.", minutesAgo: 12_990)
        ])

        add("u_omar", "Omar Haddad", "omar.h", gradient: 9, online: false, messages: [
            msg("u_omar", true, "", minutesAgo: 14_000, kind: .voice, attachment: .init(kind: .voice, name: "voice_note.m4a", duration: 67)),
            msg(meID, false, "Got it — calling you tomorrow morning.", minutesAgo: 13_990)
        ])

        add("u_nadia", "Nadia Volkova", "nadia.v", gradient: 0, online: true, messages: [
            msg("u_nadia", true, "The edit is done, exporting now.", minutesAgo: 15_500),
            msg(meID, false, "The teaser you showed was stunning.", minutesAgo: 15_490),
            msg("u_nadia", true, "Wait until you see the sound design.", minutesAgo: 15_480)
        ])

        add("u_felix", "Felix Braun", "felix.b", gradient: 1, online: false, archived: true, messages: [
            msg("u_felix", true, "Thanks for the ride yesterday!", minutesAgo: 17_000),
            msg(meID, false, "No problem at all.", minutesAgo: 16_990)
        ])

        add("u_lucia", "Lucía Fernández", "lucia.f", gradient: 2, online: true, messages: [
            msg(meID, false, "How was the conference?", minutesAgo: 18_500),
            msg("u_lucia", true, "Packed schedule, great talks. Notes incoming.", minutesAgo: 18_480)
        ])

        add("u_ethan", "Ethan Brooks", "ethan.b", gradient: 3, online: false, messages: [
            msg("u_ethan", true, "", minutesAgo: 20_000, kind: .file, attachment: .init(kind: .file, name: "contract-v2.docx")),
            msg(meID, false, "Signing today and sending it back.", minutesAgo: 19_990)
        ])

        return chats
    }

    // MARK: Contacts

    static func makeContacts() -> [Contact] {
        let people: [(String, String, Int, Bool, String)] = [
            ("Amara Diallo", "amara.d", 4, true, "+33 6 12 44 78 90"),
            ("Aiko Tanaka", "aiko.t", 5, false, "+81 90 5521 8834"),
            ("Clara Dubois", "clara.d", 9, false, "+33 7 81 22 10 45"),
            ("Daniel Okafor", "d.okafor", 3, true, "+44 7911 284 551"),
            ("Elena Petrova", "elena.p", 7, false, "+359 88 743 2210"),
            ("Ethan Brooks", "ethan.b", 3, false, "+1 415 555 0182"),
            ("Felix Braun", "felix.b", 1, false, "+49 171 555 2201"),
            ("Hana Kobayashi", "hana.k", 2, true, "+81 80 3342 9911"),
            ("Ingrid Solberg", "ingrid.s", 6, false, "+47 912 44 870"),
            ("Jonas Weber", "jonas.w", 5, false, "+49 160 443 8812"),
            ("Liam O'Connor", "liam.oc", 4, true, "+353 85 220 4471"),
            ("Lucía Fernández", "lucia.f", 2, true, "+34 612 88 30 47"),
            ("Marco Rossi", "marco.rossi", 0, false, "+39 340 118 2244"),
            ("Maya Lindqvist", "maya.l", 2, false, "+46 70 331 9902"),
            ("Nadia Volkova", "nadia.v", 0, true, "+372 5551 2280"),
            ("Noah Fischer", "noah.f", 8, true, "+41 79 220 11 84"),
            ("Omar Haddad", "omar.h", 9, false, "+961 71 442 880"),
            ("Priya Sharma", "priya.s", 6, true, "+91 98 2210 4455"),
            ("Rafael Costa", "rafa.c", 7, true, "+351 91 442 7788"),
            ("Sofia Marchetti", "sofia.m", 1, true, "+39 333 940 5511"),
            ("Tomás Herrera", "tomas.h", 1, false, "+52 55 4411 0092"),
            ("Viktor Novak", "viktor.n", 3, false, "+420 777 220 118"),
            ("Zoë Williams", "zoe.w", 8, false, "+1 212 555 0147")
        ]

        return people.map { name, username, gradient, online, phone in
            Contact(user: User(id: "c_" + username,
                               name: name,
                               username: username,
                               bio: "",
                               isOnline: online,
                               lastSeen: date(hoursAgo: Double(gradient) + 2),
                               gradientIndex: gradient),
                    phoneNumber: phone)
        }
    }
}

/// Backing store so `MockData.makeChats()` can seed message histories
/// without a circular dependency on the service layer.
enum MockMessagesStore {
    private(set) static var seeded: [String: [Message]] = [:]

    static func seed(chatID: String, messages: [Message]) {
        seeded[chatID] = messages
    }

    static func take(chatID: String) -> [Message] {
        seeded.removeValue(forKey: chatID) ?? []
    }
}
