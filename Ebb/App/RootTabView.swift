import SwiftUI

/// Четыре вкладки приложения. Таб-бар на iOS 26 стеклянный сам по себе.
struct RootTabView: View {
    enum Section: Hashable { case now, practices, diary, insights }

    @State private var selection: Section = .now

    var body: some View {
        TabView(selection: $selection) {
            Tab("Сейчас", systemImage: "water.waves", value: .now) {
                NowView()
            }
            Tab("Практики", systemImage: "circle.circle", value: .practices) {
                PracticesView()
            }
            Tab("Дневник", systemImage: "book.closed", value: .diary) {
                DiaryView()
            }
            Tab("Итоги", systemImage: "chart.bar", value: .insights) {
                InsightsView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootTabView()
}
