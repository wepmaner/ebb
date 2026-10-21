import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background(scheme)
            Text("Настройки")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text(scheme))
        }
    }
}
