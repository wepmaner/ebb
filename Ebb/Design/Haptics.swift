import UIKit

/// Короткая тактильная отдача на ключевых действиях.
enum Haptics {
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let phaseImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    /// Деление ползунка, выбор чипа.
    static func tap() { impact.impactOccurred(intensity: 0.6) }

    /// Смена фазы дыхания или группы мышц.
    static func phase() { phaseImpact.impactOccurred() }

    /// «Готово».
    static func success() { notification.notificationOccurred(.success) }
}
