import EbbCore
import SwiftUI

/// Ползунок тревоги 0–10: крупная цифра, подпись словом, трек с градиентом шкалы.
struct LevelSlider: View {
    @Binding var level: AnxietyLevel
    @Environment(\.colorScheme) private var scheme

    private let thumb: CGFloat = 32

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(level.value)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(LevelScale.numberColor(scheme: scheme))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: level)
                Text(level.label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            GeometryReader { geo in
                let width = geo.size.width
                let travel = max(1, width - thumb)
                let x = CGFloat(level.value) / 10 * travel
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: 0x4FC3B5), Color(hex: 0xE3C488), Color(hex: 0xE08A72)], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 10)
                        .opacity(0.9)
                    Circle()
                        .fill(.white)
                        .frame(width: thumb, height: thumb)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                        .overlay(Circle().stroke(LevelScale.color(for: level, scheme: scheme).opacity(0.35), lineWidth: 6).padding(-6))
                        .offset(x: x)
                        .animation(.snappy(duration: 0.2), value: level)
                }
                .frame(height: 44)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let raw = (g.location.x - thumb / 2) / travel * 10
                            let next = AnxietyLevel(clamping: Int(raw.rounded()))
                            if next != level {
                                level = next
                                Haptics.tap()
                            }
                        }
                )
            }
            .frame(height: 44)
            HStack {
                Text("спокойно")
                Spacer()
                Text("очень")
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.secondaryText(scheme).opacity(0.8))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Уровень тревоги")
        .accessibilityValue("\(level.value), \(level.label)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: level = .init(clamping: level.value + 1)
            case .decrement: level = .init(clamping: level.value - 1)
            @unknown default: break
            }
        }
        .accessibilityIdentifier("record.level")
    }
}
