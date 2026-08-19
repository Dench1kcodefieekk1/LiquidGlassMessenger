import Foundation

/// Lightweight country-code → flag mapping built on Unicode regional
/// indicator emoji (no downloaded assets). Extend `isoByDigits` to add
/// more countries.
enum CountryCodes {
    /// Longest-match-first so "+380" wins over "+3".
    static let isoByDigits: [String: String] = [
        "1": "US",
        "7": "RU",
        "20": "EG",
        "27": "ZA",
        "30": "GR",
        "31": "NL",
        "32": "BE",
        "33": "FR",
        "34": "ES",
        "36": "HU",
        "39": "IT",
        "40": "RO",
        "41": "CH",
        "43": "AT",
        "44": "GB",
        "45": "DK",
        "46": "SE",
        "47": "NO",
        "48": "PL",
        "49": "DE",
        "52": "MX",
        "54": "AR",
        "55": "BR",
        "60": "MY",
        "61": "AU",
        "62": "ID",
        "63": "PH",
        "64": "NZ",
        "65": "SG",
        "66": "TH",
        "81": "JP",
        "82": "KR",
        "84": "VN",
        "86": "CN",
        "90": "TR",
        "91": "IN",
        "92": "PK",
        "93": "AF",
        "94": "LK",
        "95": "MM",
        "98": "IR",
        "212": "MA",
        "213": "DZ",
        "216": "TN",
        "218": "LY",
        "220": "GM",
        "221": "SN",
        "233": "GH",
        "234": "NG",
        "254": "KE",
        "351": "PT",
        "352": "LU",
        "353": "IE",
        "354": "IS",
        "355": "AL",
        "358": "FI",
        "359": "BG",
        "370": "LT",
        "371": "LV",
        "372": "EE",
        "373": "MD",
        "375": "BY",
        "380": "UA",
        "381": "RS",
        "385": "HR",
        "386": "SI",
        "387": "BA",
        "389": "MK",
        "420": "CZ",
        "421": "SK",
        "855": "KH",
        "880": "BD",
        "961": "LB",
        "966": "SA",
        "971": "AE",
        "972": "IL",
        "995": "GE"
    ]

    static let maxLength = 3

    /// Flag emoji for a dialing code, longest prefix match first.
    /// Unknown codes fall back to a neutral globe.
    static func flag(forDigits digits: String) -> String {
        let cleaned = digits.filter(\.isNumber)
        var candidate = String(cleaned.prefix(maxLength))
        while !candidate.isEmpty {
            if let iso = isoByDigits[candidate] {
                return flagEmoji(iso: iso)
            }
            candidate.removeLast()
        }
        return "🌐"
    }

    /// The full recognized code the user has completed typing, if any.
    static func recognizedCode(forDigits digits: String) -> String? {
        let cleaned = digits.filter(\.isNumber)
        guard !cleaned.isEmpty else { return nil }
        var candidate = String(cleaned.prefix(maxLength))
        while !candidate.isEmpty {
            if isoByDigits[candidate] != nil {
                return candidate
            }
            candidate.removeLast()
        }
        return nil
    }

    /// ISO-3166 alpha-2 → regional indicator pair, e.g. "UA" → 🇺🇦.
    static func flagEmoji(iso: String) -> String {
        let base: UInt32 = 0x1F1E6 - 65
        let upper = iso.uppercased()
        var result = ""
        for scalar in upper.unicodeScalars {
            let value = scalar.value
            guard value >= 65, value <= 90 else { return "🌐" }
            if let indicator = Unicode.Scalar(base + value) {
                result.append(Character(indicator))
            }
        }
        return result.isEmpty ? "🌐" : result
    }
}
