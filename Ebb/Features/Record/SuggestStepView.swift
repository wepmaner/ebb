import EbbCore
import SwiftUI

/// Шаг 2: одна рекомендация и тихие альтернативы.
struct SuggestStepView: View {
    @Bindable var model: RecordFlowModel
    @Environment(Store.self) private var store
    @Environment(\.colorScheme) private var scheme
    @State private var showOtherPractices = false
    @State private var ownAction = ""

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader(step: 2, total: 4, leading: .back) { model.step = .level }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Что сделаешь")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.text(scheme))
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.secondaryText(scheme))
                    }
                    .padding(.top, 10)

                    recommendationCard

                    VStack(spacing: 10) {
                        RowButton(systemName: "list.bullet", title: "Другая практика", detail: showOtherPractices ? nil : "Заземление, проверка мысли…") {
                            withAnimation(.snappy) { showOtherPractices.toggle() }
                        }
                        if showOtherPractices {
                            otherPractices
                        }
                        ownActionBlock
                    }

                    VStack(spacing: 12) {
                        if model.recommendation?.offerDefer == true, model.displayedPrimary != .practice(.deferThought) {
                            RowButton(systemName: "clock", title: "Отложить до \(store.settings.worryTimeHour):00", detail: "время для тревоги", tint: Color(hex: 0xE3C488)) {
                                model.deferThought()
                            }
                        }
                        Button("Просто записать") { model.justRecord() }
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.secondaryText(scheme))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("record.justRecord")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var subtitle: String {
        var parts = ["Тревога \(model.draft.levelBefore.value)"]
        if let t = model.draft.trigger { parts.append(t) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Рекомендация

    private var recommendationCard: some View {
        let suggestion = model.displayedPrimary
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accent(scheme).opacity(0.18))
                    Image(systemName: icon(for: suggestion))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Theme.accentText(scheme))
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Предлагаю")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.accentText(scheme))
                    Text(title(for: suggestion))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.text(scheme))
                }
            }
            Text(description(for: suggestion))
                .font(.system(size: 15))
                .lineSpacing(3)
                .foregroundStyle(Theme.secondaryText(scheme))
            Button(suggestion == .justRecord ? "Записать" : "Начать") { model.choose(suggestion) }
                .buttonStyle(.ebbPrimary)
                .accessibilityIdentifier("record.start")
        }
        .glassCard(padding: 24)
    }

    private var otherPractices: some View {
        VStack(spacing: 8) {
            ForEach(PracticeKind.allCases, id: \.self) { kind in
                let available = RecordFlowModel.available.contains(kind)
                RowButton(systemName: icon(for: .practice(kind)), title: kind.title, detail: available ? nil : "скоро") {
                    if available { model.choose(.practice(kind)) }
                }
                .opacity(available ? 1 : 0.5)
                .disabled(!available)
            }
        }
        .padding(.leading, 12)
    }

    // MARK: - Своё действие

    private var ownActionBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.text(scheme))
                    .frame(width: 24)
                TextField("Своё действие", text: $ownAction)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.text(scheme))
                    .submitLabel(.done)
                    .onSubmit { model.chooseOwnAction(ownAction) }
                    .accessibilityIdentifier("record.ownActionField")
                if !ownAction.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Готово") { model.chooseOwnAction(ownAction) }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.accentText(scheme))
                        .accessibilityIdentifier("record.ownAction")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(scheme == .dark ? 0.06 : 0.45)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))

            if !store.ownActions.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(store.ownActions.prefix(6), id: \.name) { action in
                        Chip(title: action.name) { model.chooseOwnAction(action.name) }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }

    // MARK: - Тексты

    private func title(for s: Suggestion) -> String {
        switch s {
        case .practice(.breathing): "Дыхание · 3 минуты"
        case .practice(let k): k.title
        case .justRecord: "Просто записать"
        }
    }

    private func icon(for s: Suggestion) -> String {
        switch s {
        case .practice(.breathing): "circle.circle"
        case .practice(.grounding): "hand.raised"
        case .practice(.thoughtCheck): "questionmark.bubble"
        case .practice(.deferThought): "clock"
        case .practice(.muscleRelaxation): "figure.mind.and.body"
        case .justRecord: "checkmark"
        }
    }

    private func description(for s: Suggestion) -> String {
        switch s {
        case .practice(.breathing): "Выдох длиннее вдоха. На сильной тревоге это снимает пик быстрее всего. Потом сравним."
        case .practice(.grounding): "Пять вещей, которые видишь, четыре, которые можешь потрогать. Возвращает в комнату."
        case .practice(.thoughtCheck): "Шесть вопросов к мысли: насколько веришь, что за, что против, что сказал бы другу."
        case .practice(.deferThought): "Мысль ляжет в список до времени для тревоги. Вернёмся к ней в назначенный час."
        case .practice(.muscleRelaxation): "Напрячь и отпустить по очереди все группы мышц. Десять минут, лучше перед сном."
        case .justRecord: "Уровень невысокий. Запишем и отпустим, без практики."
        }
    }
}
