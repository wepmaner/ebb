import Foundation

/// Открытые записи (своё действие без замера «после») и их автозакрытие.
public enum EntryLifecycle {
    /// Через столько запись со своим действием закрывается без замера.
    public static let autoCloseInterval: TimeInterval = 12 * 3600

    /// Закрывает открытые записи старше `autoCloseInterval`. Остальные не трогает.
    public static func autoClose(_ entries: [Entry], now: Date) -> [Entry] {
        entries.map { entry in
            guard entry.isOpen, now.timeIntervalSince(entry.createdAt) >= autoCloseInterval else { return entry }
            var closed = entry
            closed.closedAt = EbbDates.rounded(now)
            return closed
        }
    }

    /// Открытые записи, новые первыми.
    public static func openEntries(_ entries: [Entry]) -> [Entry] {
        entries.filter(\.isOpen).sorted { $0.createdAt > $1.createdAt }
    }
}
