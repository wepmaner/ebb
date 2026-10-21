import Foundation
import Testing
@testable import EbbCore

@Test func dayKeyUsesLocalCalendarAcrossMidnight() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Europe/Moscow")!
    let d = ISO8601DateFormatter().date(from: "2026-10-21T22:30:00Z")! // 01:30 22 окт по Москве
    #expect(DayKey(d, calendar: cal).raw == "2026-10-22")
    let earlier = ISO8601DateFormatter().date(from: "2026-10-21T10:00:00Z")!
    #expect(DayKey(d, calendar: cal) > DayKey(earlier, calendar: cal))
}
