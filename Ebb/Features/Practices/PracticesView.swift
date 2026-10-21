import EbbCore
import SwiftUI

/// Список практик. Дыхание запускается само по себе, остальные появятся позже.
struct PracticesView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var showBreathing = false

    var body: some View {
        ZStack {
            Theme.background(scheme)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Практики")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.top, 8)

                    ForEach(PracticeKind.allCases.filter { $0 != .deferThought }, id: \.self) { kind in
                        let available = kind == .breathing
                        Button {
                            if available { showBreathing = true }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Theme.accent(scheme).opacity(0.18))
                                    Image(systemName: icon(kind))
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Theme.accentText(scheme))
                                }
                                .frame(width: 48, height: 48)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(kind.title)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Theme.text(scheme))
                                    Text(subtitle(kind))
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.secondaryText(scheme))
                                }
                                Spacer()
                                if !available {
                                    Text("скоро")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.secondaryText(scheme))
                                        .padding(.horizontal, 10)
                                        .frame(height: 24)
                                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!available)
                        .opacity(available ? 1 : 0.55)
                        .glassCard(padding: 18)
                        .accessibilityIdentifier("practice.\(kind.rawValue)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .fullScreenCover(isPresented: $showBreathing) {
            StandaloneBreathingFlow()
        }
    }

    private func icon(_ kind: PracticeKind) -> String {
        switch kind {
        case .breathing: "circle.circle"
        case .grounding: "hand.raised"
        case .thoughtCheck: "questionmark.bubble"
        case .deferThought: "clock"
        case .muscleRelaxation: "figure.mind.and.body"
        }
    }

    private func subtitle(_ kind: PracticeKind) -> String {
        switch kind {
        case .breathing: "2–5 минут, выдох длиннее вдоха"
        case .grounding: "Пять чувств, чтобы вернуться в комнату"
        case .thoughtCheck: "Шесть вопросов к тревожной мысли"
        case .deferThought: "До времени для тревоги"
        case .muscleRelaxation: "Десять минут перед сном"
        }
    }
}

/// Дыхание с вкладки «Практики»: выбор паттерна и длительности, по желанию замер до/после.
struct StandaloneBreathingFlow: View {
    private enum Stage { case setup, breathing, after }

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var stage: Stage = .setup
    @State private var pattern: BreathingPattern = .calm46
    @State private var minutes = 3
    @State private var measure = true
    @State private var before = AnxietyLevel(clamping: 5)
    @State private var after = AnxietyLevel(clamping: 5)
    @State private var session: BreathingSession?
    @State private var finished: PracticeSession?

    var body: some View {
        ZStack {
            Theme.background(scheme)
            switch stage {
            case .setup: setup
            case .breathing:
                if let session {
                    BreathingView(session: session) { s in
                        finished = s
                        if measure {
                            after = before
                            stage = .after
                        } else {
                            store.add(s)
                            dismiss()
                        }
                    }
                }
            case .after: afterView
            }
        }
        .animation(.snappy, value: stage == .after)
    }

    private var setup: some View {
        VStack(spacing: 0) {
            FlowHeader(step: 1, total: 1, leading: .close) { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Дыхание")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Ритм")
                        Picker("Ритм", selection: $pattern) {
                            ForEach(BreathingPattern.presets, id: \.self) { p in
                                Text(p.title).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Длительность")
                        Picker("Длительность", selection: $minutes) {
                            Text("2 мин").tag(2)
                            Text("3 мин").tag(3)
                            Text("5 мин").tag(5)
                        }
                        .pickerStyle(.segmented)
                    }
                    Toggle("Отметить уровень до и после", isOn: $measure)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.text(scheme))
                        .tint(Theme.accent(scheme))
                        .glassCard(padding: 18)
                    if measure {
                        LevelSlider(level: $before)
                            .glassCard()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            BottomBar {
                Button("Начать") {
                    session = BreathingSession(pattern: pattern, plannedSeconds: minutes * 60)
                    stage = .breathing
                }
                .buttonStyle(.ebbPrimary)
                .accessibilityIdentifier("breathing.start")
            }
        }
    }

    private var afterView: some View {
        VStack(spacing: 0) {
            FlowHeader(step: 1, total: 1, leading: .none) {}
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Как сейчас")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.top, 10)
                    LevelSlider(level: $after)
                        .glassCard()
                    Text("Было \(before.value) → стало \(after.value).")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 20)
            }
            BottomBar {
                Button("Готово") {
                    guard let finished else { dismiss(); return }
                    let entry = Entry(createdAt: finished.startedAt, levelBefore: before, coping: .practice(.breathing), levelAfter: after, afterAt: finished.endedAt)
                    store.upsert(entry)
                    var s = finished
                    s.entryID = entry.id
                    store.add(s)
                    Haptics.success()
                    dismiss()
                }
                .buttonStyle(.ebbPrimary)
            }
        }
    }
}
