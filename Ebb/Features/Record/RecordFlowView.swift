import EbbCore
import SwiftUI

/// Контейнер четырёх шагов записи. Закрывается сам, когда модель завершена.
struct RecordFlowView: View {
    @Bindable var model: RecordFlowModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background(scheme)
            Group {
                switch model.step {
                case .level:
                    LevelStepView(model: model)
                case .suggest:
                    SuggestStepView(model: model)
                case .practice(let kind):
                    PracticeStepView(kind: kind, model: model)
                case .after:
                    AfterStepView(model: model)
                }
            }
            .id(model.step)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.snappy(duration: 0.35), value: model.step)
        .onChange(of: model.isFinished) { _, finished in
            if finished { dismiss() }
        }
    }
}

/// Шаг 3: практика внутри цикла. В этой версии только дыхание.
struct PracticeStepView: View {
    let kind: PracticeKind
    @Bindable var model: RecordFlowModel
    @State private var session: BreathingSession?

    var body: some View {
        if kind == .breathing {
            BreathingView(
                session: session ?? makeSession(),
                onDone: { s in model.finishPractice(session: s) }
            )
        } else {
            VStack(spacing: 12) {
                Text(kind.title).font(.title2.bold())
                Text("Эта практика появится в следующей версии.")
                Button("Дальше") { model.step = .after }
                    .buttonStyle(.ebbPrimary)
                    .padding(.horizontal, 40)
            }
        }
    }

    private func makeSession() -> BreathingSession {
        let s = BreathingSession(pattern: .calm46, plannedSeconds: 180)
        DispatchQueue.main.async { session = s }
        return s
    }
}
