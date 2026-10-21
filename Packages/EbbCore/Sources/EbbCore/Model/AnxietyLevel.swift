/// Уровень тревоги по шкале 0–10. Значение всегда ограничено диапазоном.
public struct AnxietyLevel: Codable, Hashable, Sendable, Comparable {
    public let value: Int

    public init(clamping raw: Int) {
        value = min(10, max(0, raw))
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self.init(clamping: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }

    /// Словесная подпись: спокойно / слегка / заметно / сильно / очень.
    public var label: String {
        switch value {
        case 0...2: "спокойно"
        case 3...4: "слегка"
        case 5...6: "заметно"
        case 7...8: "сильно"
        default: "очень"
        }
    }

    public static func < (lhs: AnxietyLevel, rhs: AnxietyLevel) -> Bool { lhs.value < rhs.value }
}
