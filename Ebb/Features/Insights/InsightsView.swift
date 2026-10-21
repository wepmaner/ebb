import SwiftUI

struct InsightsView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background(scheme)
            VStack(spacing: 8) {
                Text("Итоги")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.text(scheme))
                Text("Данных пока мало.")
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
        }
    }
}
