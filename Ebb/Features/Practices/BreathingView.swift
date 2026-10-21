import EbbCore
import SwiftUI

/// Дыхание: кольца и стеклянный шар, который растёт на вдохе и сжимается на выдохе.
struct BreathingView: View {
    let session: BreathingSession
    let onDone: (PracticeSession) -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finishedHandled = false

    var body: some View {
        ZStack {
            Theme.background(scheme)
            VStack(spacing: 0) {
                header
                Spacer()
                circle
                Text(hint)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .padding(.top, 28)
                    .animation(.easeInOut, value: session.phase)
                Spacer()
                footer
            }
        }
        .task {
            if !session.isRunning, !session.isFinished { session.start() }
            while !Task.isCancelled, !session.isFinished {
                session.tick(now: Date())
                try? await Task.sleep(for: .milliseconds(33))
            }
            if session.isFinished, !finishedHandled {
                finishedHandled = true
                Haptics.success()
                onDone(session.stop())
            }
        }
    }

    // MARK: - Части

    private var header: some View {
        HStack {
            Color.clear.frame(width: Theme.iconButton, height: Theme.iconButton)
            Spacer()
            Text(session.pattern.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.secondaryText(scheme))
                .padding(.horizontal, 14)
                .frame(height: 36)
                .glassEffect(.regular, in: Capsule())
            Spacer()
            Color.clear.frame(width: Theme.iconButton, height: Theme.iconButton)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var scale: CGFloat {
        if reduceMotion { return 0.86 }
        switch session.phase {
        case .inhale: return 0.72 + 0.28 * session.progress
        case .hold: return 1.0
        case .exhale: return 1.0 - 0.28 * session.progress
        }
    }

    private var glow: Double {
        switch session.phase {
        case .inhale: 0.35 + 0.3 * session.progress
        case .hold: 0.65
        case .exhale: 0.65 - 0.3 * session.progress
        }
    }

    private var circle: some View {
        ZStack {
            Circle().stroke(Theme.accent(scheme).opacity(0.18), lineWidth: 1).frame(width: 320, height: 320)
            Circle().stroke(Theme.accent(scheme).opacity(0.28), lineWidth: 1).frame(width: 268, height: 268)
            Circle()
                .fill(RadialGradient(colors: [Theme.accent(scheme).opacity(glow), Theme.accent(scheme).opacity(0.18), Theme.accent(scheme).opacity(0)], center: .center, startRadius: 0, endRadius: 118))
                .frame(width: 236, height: 236)
                .scaleEffect(scale)
                .shadow(color: Theme.accent(scheme).opacity(0.35), radius: 40)
            Circle()
                .fill(.clear)
                .frame(width: 180, height: 180)
                .glassEffect(.regular, in: Circle())
                .scaleEffect(scale)
            VStack(spacing: 2) {
                Text(session.phase.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.text(scheme))
                    .contentTransition(.opacity)
                Text("\(session.remaining)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.accentText(scheme))
                    .contentTransition(.numericText())
            }
            .animation(.snappy, value: session.remaining)
        }
        .frame(width: 320, height: 320)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.phase.title), \(session.remaining)")
    }

    private var hint: String {
        switch session.phase {
        case .inhale: "Через нос, спокойно"
        case .hold: "Держи, не напрягаясь"
        case .exhale: "Медленно, через слегка сжатые губы"
        }
    }

    private var footer: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(clock(Int(session.elapsed)))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text(scheme))
                    .monospacedDigit()
                Text("из \(clock(session.plannedSeconds))")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            ProgressView(value: session.elapsed, total: Double(session.plannedSeconds))
                .tint(Theme.accentText(scheme))
            Button("Закончить") {
                guard !finishedHandled else { return }
                finishedHandled = true
                onDone(session.stop())
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Theme.text(scheme))
            .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
            .glassEffect(.regular.interactive(), in: Capsule())
            .accessibilityIdentifier("breathing.finish")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
