import EbbCore
import SwiftUI

/// Шаг 1: уровень, мысль, триггер, страх.
struct LevelStepView: View {
    @Bindable var model: RecordFlowModel
    @Environment(Store.self) private var store
    @Environment(\.colorScheme) private var scheme
    @State private var customTrigger = ""
    @State private var showCustomTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader(step: 1, total: 4, leading: .close) { model.cancel() }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Что сейчас")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.text(scheme))
                        .padding(.top, 10)

                    LevelSlider(level: $model.draft.levelBefore)
                        .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Что крутится в голове")
                        SoftField(placeholder: "Одна-две строки", text: thought, identifier: "record.thought")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Триггер")
                        FlowLayout(spacing: 8) {
                            ForEach(store.settings.triggers, id: \.name) { t in
                                Chip(title: t.name, selected: model.draft.trigger == t.name) {
                                    model.draft.trigger = model.draft.trigger == t.name ? nil : t.name
                                    Haptics.tap()
                                }
                            }
                            Chip(title: "+") { showCustomTrigger = true }
                                .accessibilityLabel("Свой триггер")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            SectionLabel("Чего я боюсь, что случится")
                            Text("· необязательно")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.secondaryText(scheme).opacity(0.7))
                        }
                        SoftField(placeholder: "Например: провалю презентацию", text: fear, identifier: "record.fear")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            BottomBar {
                Button("Дальше") { model.goToSuggest() }
                    .buttonStyle(.ebbPrimary)
                    .accessibilityIdentifier("record.next")
            }
        }
        .alert("Свой триггер", isPresented: $showCustomTrigger) {
            TextField("Название", text: $customTrigger)
            Button("Добавить") { addCustomTrigger() }
            Button("Отмена", role: .cancel) { customTrigger = "" }
        }
    }

    private var thought: Binding<String> {
        Binding(get: { model.draft.thought ?? "" }, set: { model.draft.thought = $0 })
    }

    private var fear: Binding<String> {
        Binding(get: { model.draft.fear ?? "" }, set: { model.draft.fear = $0 })
    }

    private func addCustomTrigger() {
        let name = customTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        customTrigger = ""
        guard !name.isEmpty else { return }
        var settings = store.settings
        if !settings.triggers.contains(where: { $0.name == name }) {
            settings.triggers.append(Trigger(name: name))
            store.save(settings: settings)
        }
        model.draft.trigger = name
    }
}

/// Перенос чипов по строкам.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
