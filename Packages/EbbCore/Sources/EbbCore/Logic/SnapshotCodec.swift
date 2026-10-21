import Foundation

public enum SnapshotError: Error, Equatable, Sendable {
    case corrupted
    case unsupportedVersion(Int)
}

/// JSON-представление Snapshot: формат резервной копии. Даты в ISO 8601.
public enum SnapshotCodec {
    public static func encode(_ snapshot: Snapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    public static func decode(_ data: Data) throws -> Snapshot {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SnapshotError.corrupted
        }
        let version = object["schemaVersion"] as? Int ?? 1
        if version > EbbCore.schemaVersion { throw SnapshotError.unsupportedVersion(version) }
        let migrated = migrate(object, from: version)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try JSONSerialization.data(withJSONObject: migrated)
            return try decoder.decode(Snapshot.self, from: data)
        } catch {
            throw SnapshotError.corrupted
        }
    }

    /// Поднимает JSON старых версий до текущей. Пока версия одна.
    static func migrate(_ object: [String: Any], from version: Int) -> [String: Any] {
        var o = object
        o["schemaVersion"] = EbbCore.schemaVersion
        return o
    }
}
