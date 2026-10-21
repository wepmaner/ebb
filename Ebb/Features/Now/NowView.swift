import SwiftUI

struct NowView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background(scheme)
            Text("Сейчас")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text(scheme))
        }
    }
}
