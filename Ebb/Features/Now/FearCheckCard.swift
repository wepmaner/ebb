import EbbCore
import SwiftUI

/// Вопрос оглядки: «ты боялся X. Это случилось?»
struct FearCheckCard: View {
    let check: FearCheck
    let entry: Entry
    let onAnswer: (FearCheck.Outcome) -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Оглядка · прошло \(check.stage == .day3 ? "3 дня" : "14 дней")")
            (Text("\(entry.createdAt.ebbShortDate) ты боялся: ")
                + Text("«\(entry.fear ?? "")»").foregroundStyle(Theme.accentText(scheme))
                + Text(". Это случилось?"))
                .font(.system(size: 17))
                .lineSpacing(2)
                .foregroundStyle(Theme.text(scheme))
            FlowLayout(spacing: 8) {
                answer("Не случилось", .didNotHappen)
                answer("Случилось, но терпимо", .happenedTolerable)
                answer("Случилось, и было плохо", .happenedBad)
            }
            Button("Пропустить") { onAnswer(.skipped) }
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondaryText(scheme))
        }
        .glassCard(padding: 18)
        .accessibilityIdentifier("now.fearCheck.\(check.id.uuidString)")
    }

    private func answer(_ title: String, _ outcome: FearCheck.Outcome) -> some View {
        Button(title) { onAnswer(outcome) }
            .buttonStyle(.ebbPill)
            .foregroundStyle(Theme.text(scheme))
    }
}
