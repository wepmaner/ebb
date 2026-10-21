import EbbCore
import SwiftUI

/// Точка входа: запись, открытые записи, вопросы оглядки, план на сегодня.
struct NowView: View {
    @Environment(Store.self) private var store
    @Environment(\.colorScheme) private var scheme
    @State private var flow: RecordFlowModel?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Theme.background(scheme)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    recordCard
                    ForEach(openEntries) { entry in
                        OpenEntryCard(entry: entry) { flow = RecordFlowModel(store: store, resuming: entry) }
                    }
                    ForEach(dueChecks) { check in
                        if let entry = store.entries.first(where: { $0.id == check.entryID }) {
                            FearCheckCard(check: check, entry: entry) { outcome in answer(check, outcome) }
                        }
                    }
                    todayCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .task { autoClose() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(item: $flow) { model in
            RecordFlowView(model: model)
                .environment(store)
        }
    }

    // MARK: - Данные

    private var openEntries: [Entry] { EntryLifecycle.openEntries(store.entries) }
    private var dueChecks: [FearCheck] { FearCheckScheduler.due(store.fearChecks, now: Date()) }

    private func autoClose() {
        let now = Date()
        let closed = EntryLifecycle.autoClose(store.entries, now: now)
        for (old, new) in zip(store.entries, closed) where old != new {
            store.upsert(new)
        }
    }

    private func answer(_ check: FearCheck, _ outcome: FearCheck.Outcome) {
        let updated = FearCheckScheduler.answer(check, outcome: outcome, in: store.fearChecks.filter { $0.entryID == check.entryID }, at: Date())
        store.replaceFearChecks(forEntry: check.entryID, with: updated)
        Haptics.tap()
    }

    // MARK: - Части

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().ebbDayTitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText(scheme))
                Text("Сейчас")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.text(scheme))
            }
            Spacer()
            IconButton(systemName: "gearshape", label: "Настройки") { showSettings = true }
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Как ты сейчас?")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.text(scheme))
            Text("Отметь уровень, запиши, что крутится, и выбери, что сделать.")
                .font(.system(size: 15))
                .lineSpacing(3)
                .foregroundStyle(Theme.secondaryText(scheme))
            Button("Записать") { flow = RecordFlowModel(store: store) }
                .buttonStyle(.ebbPrimary)
                .accessibilityIdentifier("now.record")
        }
        .glassCard()
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Сегодня")
            ForEach(store.settings.plan.filter(\.enabled)) { item in
                HStack(spacing: 12) {
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    Text(item.title)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.text(scheme))
                    Spacer()
                    Text(String(format: "%02d:00", item.hour))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
            }
        }
        .glassCard(padding: 18)
    }
}
