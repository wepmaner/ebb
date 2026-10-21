import SwiftUI

struct PracticesView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background(scheme)
            Text("Практики")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text(scheme))
        }
    }
}
