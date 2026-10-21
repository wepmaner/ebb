import SwiftData
import SwiftUI

@main
struct EbbApp: App {
    @State private var store: Store
    private let forcedScheme: ColorScheme?

    init() {
        let args = CommandLine.arguments
        let demo = args.contains("--demo-data")
        let store: Store
        if demo {
            store = Store.inMemory()
            DemoData.seed(into: store, now: Date())
        } else {
            // swiftlint:disable:next force_try
            store = try! Store.persistent()
        }
        _store = State(initialValue: store)
        if let i = args.firstIndex(of: "--ui-style"), i + 1 < args.count {
            forcedScheme = args[i + 1] == "dark" ? .dark : .light
        } else {
            forcedScheme = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .preferredColorScheme(forcedScheme)
        }
    }
}
