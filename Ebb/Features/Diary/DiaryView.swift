import EbbCore
import SwiftUI

/// Лента записей по дням с фильтрами по триггеру, способу и периоду.
struct DiaryView: View {
    @Environment(Store.self) private var store
    @Environment(\.colorScheme) private var scheme
    @State private var period: Period = .days30
    @State private var trigger: String?
    @State private var coping: CopingMethod?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(scheme)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .bottom) {
                            Text("Дневник")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Theme.text(scheme))
                            Spacer()
                            Menu {
                                Picker("Период", selection: $period) {
                                    ForEach(Period.allCases, id: \.self) { Text($0.title).tag($0) }
                                }
                            } label: {
                                Text(period.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.text(scheme))
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 4)

                        filters

                        if grouped.isEmpty {
                            Text(store.entries.isEmpty ? "Записей пока нет." : "За этот период записей нет.")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.secondaryText(scheme))
                                .padding(.horizontal, 8)
                        }

                        ForEach(grouped, id: \.day) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel(group.day.date().ebbShortDate)
                                    .padding(.horizontal, 6)
                                ForEach(group.entries) { entry in
                                    NavigationLink(value: entry.id) {
                                        DiaryRow(entry: entry, hasFearCheck: fearOutcome(entry))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let entry = store.entries.first(where: { $0.id == id }) {
                    EntryDetailView(entry: entry)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Данные

    private struct DayGroup { let day: DayKey; let entries: [Entry] }

    private var filtered: [Entry] {
        let now = Date()
        return store.entries.filter { e in
            guard period.contains(e.createdAt, now: now) else { return false }
            if let trigger, e.trigger != trigger { return false }
            if let coping, e.coping != coping { return false }
            return true
        }
    }

    private var grouped: [DayGroup] {
        let dict = Dictionary(grouping: filtered) { DayKey($0.createdAt) }
        return dict.keys.sorted(by: >).map { DayGroup(day: $0, entries: dict[$0]!.sorted { $0.createdAt > $1.createdAt }) }
    }

    private var triggersInUse: [String] {
        Array(Set(store.entries.compactMap(\.trigger))).sorted()
    }

    private var copingsInUse: [CopingMethod] {
        Array(Set(store.entries.compactMap(\.coping))).sorted { $0.displayName < $1.displayName }
    }

    private func fearOutcome(_ entry: Entry) -> FearCheck.Outcome?? {
        guard entry.hasFear else { return nil }
        let answered = store.fearChecks.filter { $0.entryID == entry.id && $0.outcome != nil && $0.outcome != .skipped }
        return .some(answered.last?.outcome)
    }

    // MARK: - Фильтры

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(triggersInUse, id: \.self) { t in
                    Chip(title: t, selected: trigger == t) { trigger = trigger == t ? nil : t }
                }
                ForEach(copingsInUse, id: \.self) { c in
                    Chip(title: c.displayName, selected: coping == c) { coping = coping == c ? nil : c }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

/// Строка дневника: капсула «7 → 3», мысль, триггер и способ, маркер оглядки.
struct DiaryRow: View {
    let entry: Entry
    /// nil — страха нет; .some(nil) — страх есть, ответа нет; .some(outcome) — ответ.
    let hasFearCheck: FearCheck.Outcome??
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            levelCapsule
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.thought ?? entry.coping?.displayName ?? "Без мысли")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.text(scheme))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                    if let t = entry.trigger { Text("· \(t)") }
                    if let c = entry.coping, entry.thought != nil { Text("· \(c.displayName)") }
                    if entry.isOpen { Text("· открыта") }
                }
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText(scheme))
            }
            Spacer(minLength: 0)
            if let outcome = hasFearCheck {
                Image(systemName: marker(outcome))
                    .font(.system(size: 15))
                    .foregroundStyle(markerColor(outcome))
                    .accessibilityLabel("Оглядка")
            }
        }
        .glassCard(padding: 16)
    }

    private var levelCapsule: some View {
        HStack(spacing: 4) {
            Text("\(entry.levelBefore.value)")
                .foregroundStyle(LevelScale.color(for: entry.levelBefore, scheme: scheme))
            if let after = entry.levelAfter {
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.secondaryText(scheme))
                Text("\(after.value)")
                    .foregroundStyle(LevelScale.color(for: after, scheme: scheme))
            }
        }
        .font(.system(size: 17, weight: .heavy, design: .rounded))
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Capsule().fill(Color.primary.opacity(scheme == .dark ? 0.1 : 0.06)))
    }

    private func marker(_ outcome: FearCheck.Outcome?) -> String {
        switch outcome {
        case .none: "questionmark.circle"
        case .didNotHappen: "checkmark.circle"
        case .happenedTolerable: "minus.circle"
        case .happenedBad: "exclamationmark.circle"
        case .skipped: "circle.dashed"
        }
    }

    private func markerColor(_ outcome: FearCheck.Outcome?) -> Color {
        switch outcome {
        case .didNotHappen: Theme.accentText(scheme)
        case .happenedBad: Color(hex: 0xE08A72)
        default: Theme.secondaryText(scheme)
        }
    }
}
