import Foundation
import Testing
@testable import EbbCore

@Test func markdownContainsPromptAndSections() {
    var s = Snapshot.empty(at: Date())
    s.entries = [Entry(levelBefore: .init(clamping: 7), thought: "мысль", trigger: "общение", fear: "страх", coping: .practice(.breathing), levelAfter: .init(clamping: 3))]
    let md = Exporter.markdown(s, period: .all, now: Date(), prompt: DefaultPrompt.text)
    #expect(md.hasPrefix(DefaultPrompt.text))
    for h in ["## Сводка", "## Записи", "## Практики", "## Оглядка", "## Привычки", "## Лестница"] {
        #expect(md.contains(h), "missing \(h)")
    }
    #expect(md.contains("7 → 3"))
    #expect(md.contains("общение"))
    #expect(md.contains("«мысль»"))
    #expect(md.contains("страх"))
}

@Test func jsonExportCarriesPromptAndFiltersPeriod() throws {
    let now = Date()
    var s = Snapshot.empty(at: now)
    s.entries = [
        Entry(createdAt: now.addingTimeInterval(-10 * 86400), levelBefore: .init(clamping: 5)),
        Entry(createdAt: now.addingTimeInterval(-1), levelBefore: .init(clamping: 5)),
    ]
    let data = try Exporter.json(s, period: .days7, now: now, prompt: "P")
    let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(obj["prompt"] as? String == "P")
    #expect((obj["entries"] as! [Any]).count == 1)
    #expect(obj["schemaVersion"] as? Int == 1)
}

@Test func filteredKeepsSessionsOfKeptEntriesOnly() {
    let now = Date()
    var s = Snapshot.empty(at: now)
    let old = Entry(createdAt: now.addingTimeInterval(-10 * 86400), levelBefore: .init(clamping: 5))
    let new = Entry(createdAt: now.addingTimeInterval(-1), levelBefore: .init(clamping: 5))
    s.entries = [old, new]
    s.sessions = [
        PracticeSession(entryID: old.id, kind: .breathing, startedAt: old.createdAt, endedAt: old.createdAt, details: .breathing(pattern: .calm46, plannedSeconds: 1, actualSeconds: 1)),
        PracticeSession(entryID: nil, kind: .breathing, startedAt: now, endedAt: now, details: .breathing(pattern: .calm46, plannedSeconds: 1, actualSeconds: 1)),
    ]
    let f = Exporter.filtered(s, period: .days7, now: now)
    #expect(f.entries.map(\.id) == [new.id])
    #expect(f.sessions.count == 1)
    #expect(f.sessions[0].entryID == nil)
}

@Test func defaultPromptMentionsAvoidanceAndScale() {
    #expect(DefaultPrompt.text.contains("избегани"))
    #expect(DefaultPrompt.text.contains("0 до 10"))
    #expect(DefaultPrompt.text.contains("специалист"))
}
