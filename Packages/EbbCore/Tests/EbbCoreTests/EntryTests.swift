import Foundation
import Testing
@testable import EbbCore

@Test func entryIsOpenOnlyForOwnActionWithoutAfter() {
    var e = Entry(levelBefore: .init(clamping: 7), coping: .ownAction("гулял"))
    #expect(e.isOpen)
    e.levelAfter = .init(clamping: 3)
    #expect(!e.isOpen)
    #expect(e.delta == -4)
    let p = Entry(levelBefore: .init(clamping: 7), coping: .practice(.breathing))
    #expect(!p.isOpen)
}

@Test func entryCodableRoundTrip() throws {
    let e = Entry(levelBefore: .init(clamping: 5), thought: "x", trigger: "общение", fear: "y", coping: .practice(.breathing))
    let data = try JSONEncoder().encode(e)
    let decoded = try JSONDecoder().decode(Entry.self, from: data)
    #expect(decoded == e)
}

@Test func copingDisplayNames() {
    #expect(CopingMethod.practice(.breathing).displayName == "Дыхание")
    #expect(CopingMethod.ownAction("гулял").displayName == "гулял")
    #expect(CopingMethod.justRecord.displayName == "Просто записал")
}

@Test func defaultTriggersMatchSpec() {
    #expect(Trigger.defaults.map(\.name) == ["общение", "работа", "здоровье", "деньги", "отношения", "не знаю"])
    #expect(Trigger.defaults.allSatisfy { $0.isBuiltIn })
}
