import EbbCore
import SwiftUI

/// Шаг 4: уровень после и сравнение.
struct AfterStepView: View {
    @Bindable var model: RecordFlowModel
    @Environment(Store.self) private var store
    @Environment(\.colorScheme) private var scheme
    @State private var after: AnxietyLevel
    @State private var touched = false

    init(model: RecordFlowModel) {
        self.model = model
        _after = State(initialValue: model.draft.levelAfter ?? model.draft.levelBefore)
    }

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader(step: 4, total: 4, leading: model.isResuming ? .close : .none) { model.cancel() }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Как сейчас")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.top, 10)

                    if model.isResuming, let coping = model.draft.coping {
                        Text("Ты писал: тревога \(model.draft.levelBefore.value), \(coping.displayName). Прошло \(model.draft.createdAt.ebbRelative().replacingOccurrences(of: " назад", with: ""))." )
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.secondaryText(scheme))
                    }

                    LevelSlider(level: $after)
                        .glassCard()
                        .onChange(of: after) { touched = true }

                    comparisonCard

                    if model.draft.hasFear, let fear = model.draft.fear {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Страх записан")
                            Text("«\(fear)». Спрошу через 3 дня, сбылось ли.")
                                .font(.system(size: 16))
                                .lineSpacing(2)
                                .foregroundStyle(Theme.text(scheme))
                        }
                        .glassCard(padding: 18)
                    }

                    if let line = statsLine {
                        Text(line)
                            .font(.system(size: 14))
                            .lineSpacing(3)
                            .foregroundStyle(Theme.secondaryText(scheme))
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            BottomBar {
                Button("Готово") {
                    model.setAfter(after)
                    model.finish()
                    Haptics.success()
                }
                .buttonStyle(.ebbPrimary)
                .accessibilityIdentifier("record.done")
            }
        }
    }

    // MARK: - Сравнение

    private var delta: Int { after.value - model.draft.levelBefore.value }

    private var comparisonCard: some View {
        VStack(spacing: 22) {
            HStack(spacing: 22) {
                bigNumber(model.draft.levelBefore.value, color: LevelScale.numberColor(scheme: scheme), caption: "было")
                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.secondaryText(scheme))
                bigNumber(after.value, color: delta < 0 ? Theme.accentText(scheme) : LevelScale.color(for: after, scheme: scheme), caption: "стало")
            }
            Text(verdict)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.text(scheme))
            Divider().overlay(Color.primary.opacity(0.1))
            HStack {
                detail("способ", model.draft.coping?.displayName ?? "—")
                detail("длилось", duration)
                detail("триггер", model.draft.trigger ?? "—")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 22)
    }

    private func bigNumber(_ n: Int, color: Color, caption: String) -> some View {
        VStack(spacing: 4) {
            Text("\(n)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText(scheme))
        }
    }

    private func detail(_ k: String, _ v: String) -> some View {
        VStack(spacing: 3) {
            Text(k).font(.system(size: 13)).foregroundStyle(Theme.secondaryText(scheme))
            Text(v).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.text(scheme)).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var verdict: String {
        if delta < 0 { return "Стало спокойнее на \((-delta).ebbPoints)." }
        if delta == 0 { return "Не изменилось. Это тоже данные." }
        return "Не помогло в этот раз. Это тоже данные."
    }

    private var duration: String {
        let seconds: Int
        if let s = model.session {
            seconds = s.durationSeconds
        } else {
            seconds = Int(Date().timeIntervalSince(model.draft.createdAt))
        }
        if seconds < 90 { return "\(max(1, seconds)) с" }
        if seconds < 3600 { return "\(seconds / 60) мин" }
        return "\(seconds / 3600) ч"
    }

    private var statsLine: String? {
        guard let coping = model.draft.coping else { return nil }
        let stats = Stats.methods(store.entries, period: .days30, now: Date())
        guard let m = stats.first(where: { $0.method == coping }), !m.isLowData, m.averageDelta < 0 else { return nil }
        let avg = (-m.averageDelta * 10).rounded() / 10
        let text = avg == avg.rounded() ? "\(Int(avg))" : String(avg).replacingOccurrences(of: ".", with: ",")
        return "За месяц «\(coping.displayName.lowercased())» снижало тревогу в среднем на \(text). Это твои данные, не обещание."
    }
}
