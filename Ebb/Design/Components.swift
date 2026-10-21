import EbbCore
import SwiftUI

/// Мелкие общие элементы: подписи, чипы, поля, шапка шагов, прокрутка с фоном.

struct SectionLabel: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.secondaryText(scheme))
    }
}

/// Чип выбора (триггер, своё действие).
struct Chip: View {
    let title: String
    var selected = false
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(selected ? Theme.accentText(scheme) : Theme.text(scheme))
                .padding(.horizontal, 16)
                .frame(minHeight: Theme.chipHeight)
                .background(
                    Capsule().fill(selected ? Theme.accent(scheme).opacity(scheme == .dark ? 0.22 : 0.16) : Color.white.opacity(scheme == .dark ? 0.07 : 0.6))
                )
                .overlay(Capsule().stroke(selected ? Theme.accent(scheme) : Color.primary.opacity(scheme == .dark ? 0.16 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Многострочное поле на мягкой подложке.
struct SoftField: View {
    let placeholder: String
    @Binding var text: String
    var identifier: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(2...4)
            .font(.system(size: 16))
            .foregroundStyle(Theme.text(scheme))
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(scheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(scheme == .dark ? 0.1 : 0.1), lineWidth: 1)
            )
            .accessibilityIdentifier(identifier ?? placeholder)
    }
}

/// Шапка шага: круглая кнопка слева, точки прогресса по центру.
struct FlowHeader: View {
    enum Leading { case close, back, none }
    let step: Int
    let total: Int
    let leading: Leading
    let onLeading: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack {
            ZStack {
                if leading != .none {
                    Button(action: onLeading) {
                        Image(systemName: leading == .close ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.text(scheme))
                            .frame(width: Theme.iconButton, height: Theme.iconButton)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel(leading == .close ? "Закрыть" : "Назад")
                }
            }
            .frame(width: Theme.iconButton, height: Theme.iconButton)
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Theme.accentText(scheme) : Color.primary.opacity(0.25))
                        .frame(width: i == step ? 22 : 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Шаг \(step) из \(total)")
            Spacer()
            Color.clear.frame(width: Theme.iconButton, height: Theme.iconButton)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

/// Круглая кнопка-иконка на стекле.
struct IconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.text(scheme))
                .frame(width: Theme.iconButton, height: Theme.iconButton)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(label)
    }
}

/// Строка-кнопка с иконкой слева и подписью справа.
struct RowButton: View {
    let systemName: String
    let title: String
    var detail: String? = nil
    var tint: Color? = nil
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint ?? Theme.text(scheme))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.text(scheme))
                Spacer(minLength: 8)
                if let detail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText(scheme))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill((tint ?? Color.white).opacity(scheme == .dark ? 0.06 : 0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke((tint ?? Color.primary).opacity(scheme == .dark ? 0.12 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Нижняя закреплённая основная кнопка.
struct BottomBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
    }
}

extension Date {
    /// «Вторник, 21 октября».
    var ebbDayTitle: String {
        let s = formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "ru_RU")))
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// «18 октября».
    var ebbShortDate: String {
        formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "ru_RU")))
    }

    /// «14:17», всегда 24-часовой формат.
    var ebbTime: String {
        formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().locale(Locale(identifier: "ru_RU")))
    }

    /// «21 октября, 14:17».
    var ebbDateTime: String {
        "\(ebbShortDate), \(ebbTime)"
    }

    /// «40 мин назад», «2 ч назад».
    func ebbRelative(to now: Date = Date()) -> String {
        let minutes = Int(now.timeIntervalSince(self) / 60)
        if minutes < 1 { return "только что" }
        if minutes < 60 { return "\(minutes) мин назад" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) ч назад" }
        return "\(hours / 24) дн назад"
    }
}

extension Int {
    /// «4 пункта», «1 пункт», «5 пунктов».
    var ebbPoints: String {
        let n = abs(self) % 100
        let last = n % 10
        if n > 10, n < 20 { return "\(abs(self)) пунктов" }
        if last == 1 { return "\(abs(self)) пункт" }
        if (2...4).contains(last) { return "\(abs(self)) пункта" }
        return "\(abs(self)) пунктов"
    }
}
