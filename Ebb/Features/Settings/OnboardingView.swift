import SwiftUI
import UniformTypeIdentifiers

/// Первый запуск с пустой базой: восстановить из копии или начать с чистого листа.
struct OnboardingView: View {
    @Environment(BackupService.self) private var backup
    @Environment(\.colorScheme) private var scheme
    let onDone: () -> Void
    @State private var pickRestore = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Theme.background(scheme)
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "water.waves")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Theme.accentText(scheme))
                Text("Ebb")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.text(scheme))
                Text("Дневник тревоги. Всё хранится только на этом телефоне.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .padding(.horizontal, 32)
                Spacer()
                VStack(spacing: 12) {
                    Text("Уже вёл дневник раньше?")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.secondaryText(scheme))
                    Button("Восстановить из резервной копии") { pickRestore = true }
                        .buttonStyle(.ebbPrimary)
                    Button("Начать с чистого листа") { onDone() }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.text(scheme))
                        .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
                        .glassEffect(.regular.interactive(), in: Capsule())
                        .accessibilityIdentifier("onboarding.fresh")
                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .fileImporter(isPresented: $pickRestore, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            do {
                try backup.restore(from: url)
                onDone()
            } catch {
                self.error = "Файл не подошёл: \(error.localizedDescription)"
            }
        }
    }
}
