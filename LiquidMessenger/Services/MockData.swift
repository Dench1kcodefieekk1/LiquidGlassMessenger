import Foundation

/// Deterministic seed data. V2 keeps no demo conversations — the only
/// default chat (Saved Messages) is created by `ChatService` on first launch.
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

    // MARK: Helpers

    private static func date(hoursAgo: Double) -> Date {
        Date().addingTimeInterval(-(hoursAgo * 3_600))
    }

    // MARK: Simulated peer replies

    static let cannedReplies: [String] = [
        "Sounds good 👌",
        "Got it, thanks!",
        "Let me check and get back to you.",
        "Haha, exactly.",
        "Can we talk tomorrow?",
        "On my way.",
        "Interesting — tell me more.",
        "Perfect, see you then!",
        "I was just thinking the same thing.",
        "Sure, no problem."
    ]

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
