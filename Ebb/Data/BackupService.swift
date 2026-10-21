import EbbCore
import Foundation

/// Пишет резервную копию в папку, выбранную пользователем в «Файлах», и восстанавливает из файла.
@Observable
@MainActor
final class BackupService {
    static let fileName = "ebb-backup.json"
    static let staleAfter: TimeInterval = 3 * 86400
    static let datedEvery: TimeInterval = 7 * 86400
    static let datedKeep = 8

    private let store: Store
    private let defaults: UserDefaults
    private let fileManager: FileManager
    private let debounce: Duration
    private let clock: () -> Date
    private var pending: Task<Void, Never>?

    /// false в демо-режиме: ничего не пишет и не показывает карточку.
    let isEnabled: Bool

    private(set) var folderURL: URL?
    private(set) var lastError: String?

    init(store: Store, defaults: UserDefaults = .standard, fileManager: FileManager = .default, debounce: Duration = .seconds(3), clock: @escaping () -> Date = Date.init, enabled: Bool = true) {
        self.store = store
        self.defaults = defaults
        self.fileManager = fileManager
        self.debounce = debounce
        self.clock = clock
        self.isEnabled = enabled
        folderURL = Self.resolveBookmark(defaults.data(forKey: Keys.bookmark))
    }

    private enum Keys {
        static let bookmark = "backup.bookmark"
        static let lastAt = "backup.lastAt"
        static let lastDatedAt = "backup.lastDatedAt"
    }

    var lastBackupAt: Date? { defaults.object(forKey: Keys.lastAt) as? Date }
    private var lastDatedAt: Date? { defaults.object(forKey: Keys.lastDatedAt) as? Date }

    /// Папка выбрана, а свежей копии нет.
    var isStale: Bool {
        guard isEnabled, folderURL != nil else { return false }
        guard let last = lastBackupAt else { return true }
        return clock().timeIntervalSince(last) > Self.staleAfter
    }

    // MARK: - Папка

    func setFolder(_ url: URL) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        defaults.set(data, forKey: Keys.bookmark)
        defaults.removeObject(forKey: Keys.lastAt)
        defaults.removeObject(forKey: Keys.lastDatedAt)
        folderURL = url
        lastError = nil
    }

    private static func resolveBookmark(_ data: Data?) -> URL? {
        guard let data else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    // MARK: - Запись

    /// Отложенная запись: несколько изменений подряд дают одну копию.
    func scheduleBackup() {
        guard isEnabled, folderURL != nil else { return }
        pending?.cancel()
        let delay = debounce
        pending = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            try? self.backupNow()
        }
    }

    func backupNow() throws {
        guard isEnabled, let folder = folderURL else { return }
        let accessed = folder.startAccessingSecurityScopedResource()
        defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
        do {
            let now = clock()
            let data = try SnapshotCodec.encode(store.snapshot(at: now))
            try data.write(to: folder.appending(path: Self.fileName), options: .atomic)
            if lastDatedAt.map({ now.timeIntervalSince($0) >= Self.datedEvery }) ?? true {
                try data.write(to: folder.appending(path: "ebb-backup-\(DayKey(now).raw).json"), options: .atomic)
                defaults.set(now, forKey: Keys.lastDatedAt)
                pruneDated(in: folder)
            }
            defaults.set(now, forKey: Keys.lastAt)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    private func pruneDated(in folder: URL) {
        guard let names = try? fileManager.contentsOfDirectory(atPath: folder.path) else { return }
        let dated = names.filter { $0.hasPrefix("ebb-backup-") && $0.hasSuffix(".json") }.sorted()
        for name in dated.dropLast(Self.datedKeep) {
            try? fileManager.removeItem(at: folder.appending(path: name))
        }
    }

    // MARK: - Восстановление

    /// Заменяет базу содержимым файла. Повреждённый файл не трогает базу.
    func restore(from url: URL) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let snapshot = try SnapshotCodec.decode(data)
        try store.replaceAll(with: snapshot)
    }
}
