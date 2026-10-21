import EbbCore
import Foundation
import Testing
@testable import Ebb

@MainActor
private func tempFolder() throws -> URL {
    let dir = FileManager.default.temporaryDirectory.appending(path: "ebb-test-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

@MainActor
private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "ebb-test-\(UUID().uuidString)")!
}

@Test @MainActor func backupWritesFileAndRestoreRoundTrips() throws {
    let dir = try tempFolder()
    let s = Store.inMemory()
    s.upsert(Entry(levelBefore: .init(clamping: 4), thought: "т", coping: .ownAction("гулял")))
    let b = BackupService(store: s, defaults: freshDefaults())
    try b.setFolder(dir)
    #expect(b.folderURL?.lastPathComponent == dir.lastPathComponent)
    try b.backupNow()
    let file = dir.appending(path: "ebb-backup.json")
    #expect(FileManager.default.fileExists(atPath: file.path))
    #expect(b.lastBackupAt != nil)
    #expect(!b.isStale)

    let s2 = Store.inMemory()
    let b2 = BackupService(store: s2, defaults: freshDefaults())
    try b2.restore(from: file)
    #expect(s2.entries == s.entries)
}

@Test @MainActor func backupKeepsDatedCopiesWeekly() throws {
    let dir = try tempFolder()
    let s = Store.inMemory()
    let defaults = freshDefaults()
    var now = Date(timeIntervalSince1970: 1_800_000_000)
    let b = BackupService(store: s, defaults: defaults, clock: { now })
    try b.setFolder(dir)
    try b.backupNow()
    now = now.addingTimeInterval(86400)
    try b.backupNow()
    var dated = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasPrefix("ebb-backup-") }
    #expect(dated.count == 1)
    now = now.addingTimeInterval(7 * 86400)
    try b.backupNow()
    dated = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasPrefix("ebb-backup-") }
    #expect(dated.count == 2)
}

@Test @MainActor func corruptedRestoreLeavesStoreUntouched() throws {
    let dir = try tempFolder()
    let url = dir.appending(path: "bad.json")
    try Data("{\"schemaVersion\":1,".utf8).write(to: url)
    let s = Store.inMemory()
    s.upsert(Entry(levelBefore: .init(clamping: 4)))
    let b = BackupService(store: s, defaults: freshDefaults())
    #expect(throws: (any Error).self) { try b.restore(from: url) }
    #expect(s.entries.count == 1)
}

@Test @MainActor func scheduleBackupDebouncesAndWrites() async throws {
    let dir = try tempFolder()
    let s = Store.inMemory()
    let b = BackupService(store: s, defaults: freshDefaults(), debounce: .milliseconds(50))
    try b.setFolder(dir)
    s.onChange = { b.scheduleBackup() }
    s.upsert(Entry(levelBefore: .init(clamping: 3)))
    s.upsert(Entry(levelBefore: .init(clamping: 5)))
    try await Task.sleep(for: .milliseconds(400))
    let file = dir.appending(path: "ebb-backup.json")
    #expect(FileManager.default.fileExists(atPath: file.path))
    let restored = try SnapshotCodec.decode(Data(contentsOf: file))
    #expect(restored.entries.count == 2)
}

@Test @MainActor func staleWhenFolderSetButOldBackup() throws {
    let dir = try tempFolder()
    var now = Date(timeIntervalSince1970: 1_800_000_000)
    let b = BackupService(store: Store.inMemory(), defaults: freshDefaults(), clock: { now })
    #expect(!b.isStale)
    try b.setFolder(dir)
    #expect(b.isStale)
    try b.backupNow()
    #expect(!b.isStale)
    now = now.addingTimeInterval(4 * 86400)
    #expect(b.isStale)
}
