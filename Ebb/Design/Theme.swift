import SwiftUI

extension Color {
    /// Цвет из шестнадцатеричного значения вида 0x4FC3B5 в sRGB.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Токены из утверждённых макетов. Единственное место, где живут цвета.
enum Theme {
    // Акцент
    static let accent = Color(hex: 0x4FC3B5)
    static let accentLight = Color(hex: 0x1F8F82)
    static let accentText = Color(hex: 0x8AE3D7)
    static let accentTextLight = Color(hex: 0x177C70)
    static let onAccent = Color(hex: 0x06201F)

    // Текст
    static let textDark = Color(hex: 0xF2F4F3)
    static let textLight = Color(hex: 0x0F1F24)
    static let secondaryLight = Color(hex: 0x4A5C61)

    static func accent(_ scheme: ColorScheme) -> Color { scheme == .dark ? accent : accentLight }
    static func onAccent(_ scheme: ColorScheme) -> Color { scheme == .dark ? onAccent : .white }
    static func accentText(_ scheme: ColorScheme) -> Color { scheme == .dark ? accentText : accentTextLight }
    static func text(_ scheme: ColorScheme) -> Color { scheme == .dark ? textDark : textLight }
    static func secondaryText(_ scheme: ColorScheme) -> Color { scheme == .dark ? textDark.opacity(0.65) : secondaryLight }

    /// Фон «отлив»: линейный градиент и два мягких пятна. Не зависит от уровня тревоги.
    static func background(_ scheme: ColorScheme) -> some View {
        EbbBackground(scheme: scheme)
    }

    static let cardRadius: CGFloat = 28
    static let buttonHeight: CGFloat = 54
    static let chipHeight: CGFloat = 40
    static let iconButton: CGFloat = 44
}

struct EbbBackground: View {
    let scheme: ColorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(colors: linear, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [spotA, spotA.opacity(0)], center: .init(x: 0.2, y: drift ? 0.05 : 0), startRadius: 0, endRadius: 420)
            RadialGradient(colors: [spotB, spotB.opacity(0)], center: .init(x: 0.9, y: drift ? 0.95 : 1), startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private var linear: [Color] {
        scheme == .dark
            ? [Color(hex: 0x0A1B22), Color(hex: 0x0E2630), Color(hex: 0x182A2C)]
            : [Color(hex: 0xEEF5F3), Color(hex: 0xF3F4EF), Color(hex: 0xF7F2E8)]
    }
    private var spotA: Color { scheme == .dark ? Color(hex: 0x174650) : Color(hex: 0xC9EBE4) }
    private var spotB: Color { scheme == .dark ? Color(hex: 0x3F3826) : Color(hex: 0xF1E3C6) }
}

/// Стеклянная карточка: Liquid Glass поверх фона, радиус 28.
struct GlassCard: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

/// Основная кнопка: капсула 54 pt, акцентная заливка.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.onAccent(scheme))
            .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
            .background(Theme.accent(scheme), in: Capsule())
            .shadow(color: Theme.accent(scheme).opacity(0.35), radius: 12, y: 8)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Тихая кнопка-капсула на стекле: 44 pt.
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 16)
            .frame(minHeight: Theme.iconButton)
            .glassEffect(.regular.interactive(), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension View {
    func glassCard(padding: CGFloat = 22) -> some View { modifier(GlassCard(padding: padding)) }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var ebbPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var ebbPill: PillButtonStyle { PillButtonStyle() }
}
