import SwiftData
import SwiftUI

@main
struct EbbApp: App {
    @State private var store: Store
    @State private var backup: BackupService
    @State private var needsOnboarding: Bool
    private let forcedScheme: ColorScheme?

    private static let onboardingKey = "onboarding.done"

    init() {
        let args = CommandLine.arguments
        let demo = args.contains("--demo-data")
        let store: Store
        let backup: BackupService
        if demo {
            store = Store.inMemory()
            DemoData.seed(into: store, now: Date())
            backup = BackupService(store: store, defaults: UserDefaults(suiteName: "ebb-demo")!, enabled: false)
            needsOnboarding = args.contains("--onboarding")
        } else {
            // swiftlint:disable:next force_try
            store = try! Store.persistent()
            backup = BackupService(store: store)
            needsOnboarding = store.isEmpty && !UserDefaults.standard.bool(forKey: Self.onboardingKey)
        }
        store.onChange = { [backup] in backup.scheduleBackup() }
        _store = State(initialValue: store)
        _backup = State(initialValue: backup)
        if let i = args.firstIndex(of: "--ui-style"), i + 1 < args.count {
            forcedScheme = args[i + 1] == "dark" ? .dark : .light
        } else {
            forcedScheme = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if needsOnboarding {
                    OnboardingView {
                        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
                        withAnimation(.snappy) { needsOnboarding = false }
                    }
                } else {
                    RootTabView()
                }
            }
            .environment(store)
            .environment(backup)
            .preferredColorScheme(forcedScheme)
        }
    }
}
