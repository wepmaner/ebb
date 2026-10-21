import EbbCore
import SwiftUI

/// Запись со своим действием, у которой ещё нет замера «после».
struct OpenEntryCard: View {
    let entry: Entry
    let onResume: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Открытая запись · \(entry.createdAt.ebbRelative())")
            HStack(spacing: 0) {
                Text("Тревога ")
                Text("\(entry.levelBefore.value)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(LevelScale.numberColor(scheme: scheme))
                Text(", \(entry.coping?.displayName ?? "").")
            }
            .font(.system(size: 17))
            .foregroundStyle(Theme.text(scheme))
            Button("Как сейчас?", action: onResume)
                .buttonStyle(.ebbPill)
                .foregroundStyle(Theme.text(scheme))
                .accessibilityIdentifier("now.openEntry.\(entry.id.uuidString)")
        }
        .glassCard(padding: 18)
    }
}
