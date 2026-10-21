import Foundation
import Testing
@testable import EbbCore

@Test func codecRoundTrip() throws {
    var s = Snapshot.empty(at: Date(timeIntervalSince1970: 1_800_000_000))
    s.entries = [Entry(createdAt: Date(timeIntervalSince1970: 1_799_999_000), levelBefore: .init(clamping: 7), thought: "т", coping: .ownAction("гулял"))]
    let data = try SnapshotCodec.encode(s)
    let decoded = try SnapshotCodec.decode(data)
    #expect(decoded == s)
    #expect(String(decoding: data, as: UTF8.self).contains("\"schemaVersion\" : 1"))
}

@Test func codecRejectsCorruptedData() {
    #expect(throws: SnapshotError.self) { try SnapshotCodec.decode(Data("{\"schemaVersion\":1,\"entries\":[".utf8)) }
    #expect(throws: SnapshotError.self) { try SnapshotCodec.decode(Data()) }
}

@Test func codecRejectsUnsupportedVersion() {
    #expect(throws: SnapshotError.unsupportedVersion(99)) { try SnapshotCodec.decode(Data("{\"schemaVersion\":99}".utf8)) }
}
