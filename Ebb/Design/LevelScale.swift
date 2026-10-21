import EbbCore
import SwiftUI

/// Цвет уровня тревоги: бирюза (0) → песок (5–6) → приглушённый коралл (10).
enum LevelScale {
    private static let low: (Double, Double, Double) = rgb(0x4FC3B5)
    private static let mid: (Double, Double, Double) = rgb(0xE3C488)
    private static let high: (Double, Double, Double) = rgb(0xE08A72)

    static func color(for level: AnxietyLevel, scheme: ColorScheme) -> Color {
        let t = Double(level.value) / 10
        let (a, b, local) = t < 0.55 ? (low, mid, t / 0.55) : (mid, high, (t - 0.55) / 0.45)
        let r = a.0 + (b.0 - a.0) * local
        let g = a.1 + (b.1 - a.1) * local
        let bl = a.2 + (b.2 - a.2) * local
        return Color(.sRGB, red: r, green: g, blue: bl, opacity: 1)
    }

    /// Цвет крупной цифры уровня на экранах записи.
    static func numberColor(scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xE3C488) : Color(hex: 0xA8761E)
    }

    private static func rgb(_ hex: UInt32) -> (Double, Double, Double) {
        (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }
}
