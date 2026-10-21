import SwiftUI

struct DiaryView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background(scheme)
            Text("Дневник")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text(scheme))
        }
    }
}
