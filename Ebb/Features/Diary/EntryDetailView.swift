import EbbCore
import SwiftUI

/// Одна запись целиком: уровни, мысль, страх и его исход, сессия практики. Правка и удаление.
struct EntryDetailView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let entry: Entry
    @State private var editing = false
    @State private var thought = ""
    @State private var trigger: String?
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            Theme.background(scheme)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(entry.createdAt.formatted(.dateTime.day().month(.wide).hour().minute().locale(Locale(identifier: "ru_RU"))))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.top, 4)

                    levels
                    if entry.hasThought || entry.trigger != nil { thoughtCard }
                    if entry.hasFear { fearCard }
                    if let session = store.sessions.first(where: { $0.entryID == entry.id }) { sessionCard(session) }

                    Button("Удалить запись", role: .destructive) { confirmDelete = true }
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .navigationTitle("Запись")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Изменить") {
                    thought = entry.thought ?? ""
                    trigger = entry.trigger
                    editing = true
                }
            }
        }
        .sheet(isPresented: $editing) { editor }
        .confirmationDialog("Удалить эту запись?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                store.delete(entryID: entry.id)
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Карточки

    private var levels: some View {
        HStack(spacing: 22) {
            VStack(spacing: 4) {
                Text("\(entry.levelBefore.value)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(LevelScale.color(for: entry.levelBefore, scheme: scheme))
                Text("до").font(.system(size: 13)).foregroundStyle(Theme.secondaryText(scheme))
            }
            if let after = entry.levelAfter {
                Image(systemName: "arrow.right").foregroundStyle(Theme.secondaryText(scheme))
                VStack(spacing: 4) {
                    Text("\(after.value)")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(LevelScale.color(for: after, scheme: scheme))
                    Text("после").font(.system(size: 13)).foregroundStyle(Theme.secondaryText(scheme))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if let c = entry.coping {
                    Text(c.displayName).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.text(scheme))
                }
                if entry.isOpen {
                    Text("открыта").font(.system(size: 13)).foregroundStyle(Theme.secondaryText(scheme))
                } else if entry.levelAfter == nil, entry.closedAt != nil {
                    Text("без замера после").font(.system(size: 13)).foregroundStyle(Theme.secondaryText(scheme))
                }
            }
        }
        .glassCard()
    }

    private var thoughtCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let t = entry.trigger { SectionLabel("Триггер · \(t)") } else { SectionLabel("Мысль") }
            if let thought = entry.thought {
                Text(thought).font(.system(size: 17)).lineSpacing(3).foregroundStyle(Theme.text(scheme))
            }
        }
        .glassCard(padding: 18)
    }

    private var fearCard: some View {
        let checks = store.fearChecks.filter { $0.entryID == entry.id }.sorted { $0.dueAt < $1.dueAt }
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Чего боялся")
            Text("«\(entry.fear ?? "")»").font(.system(size: 17)).foregroundStyle(Theme.text(scheme))
            ForEach(checks) { c in
                HStack {
                    Text(c.stage == .day3 ? "Через 3 дня" : "Через 14 дней")
                    Spacer()
                    Text(outcomeTitle(c))
                }
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondaryText(scheme))
            }
        }
        .glassCard(padding: 18)
    }

    private func sessionCard(_ s: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("\(s.kind.title) · \(s.durationSeconds / 60) мин \(s.durationSeconds % 60) с")
            switch s.details {
            case .breathing(let p, let planned, let actual):
                Text("\(p.title), \(actual) с из \(planned)").font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
            case .thoughtCheck(_, let before, let pro, let contra, let friend, let after):
                Text("Верил \(before)% → \(after)%").font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.text(scheme))
                Text("За: \(pro)").font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
                Text("Против: \(contra)").font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
                Text("Другу: \(friend)").font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
            case .grounding(let see, let touch, let hear, let smell, let taste):
                Text([see, touch, hear, smell, taste].flatMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "))
                    .font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
            case .deferred:
                Text("Мысль отложена").font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
            case .muscleRelaxation(let groups, _):
                Text("Групп мышц: \(groups)").font(.system(size: 15)).foregroundStyle(Theme.text(scheme))
            }
        }
        .glassCard(padding: 18)
    }

    private func outcomeTitle(_ c: FearCheck) -> String {
        switch c.outcome {
        case .none: c.dueAt > Date() ? "спрошу \(c.dueAt.ebbShortDate)" : "ждёт ответа"
        case .didNotHappen: "не случилось"
        case .happenedTolerable: "случилось, терпимо"
        case .happenedBad: "случилось, было плохо"
        case .skipped: "пропущено"
        }
    }

    // MARK: - Правка

    private var editor: some View {
        NavigationStack {
            Form {
                Section("Мысль") {
                    TextField("Что крутилось в голове", text: $thought, axis: .vertical).lineLimit(2...5)
                }
                Section("Триггер") {
                    Picker("Триггер", selection: $trigger) {
                        Text("нет").tag(String?.none)
                        ForEach(store.settings.triggers, id: \.name) { t in
                            Text(t.name).tag(String?.some(t.name))
                        }
                    }
                }
            }
            .navigationTitle("Изменить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { editing = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        var e = entry
                        let t = thought.trimmingCharacters(in: .whitespacesAndNewlines)
                        e.thought = t.isEmpty ? nil : t
                        e.trigger = trigger
                        store.upsert(e)
                        editing = false
                        dismiss()
                    }
                }
            }
        }
    }
}
