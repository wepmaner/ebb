import EbbCore
import SwiftUI
import Testing
@testable import Ebb

@Test func levelScaleEndsMatchTokens() {
    #expect(LevelScale.color(for: .init(clamping: 0), scheme: .dark) == Color(hex: 0x4FC3B5))
    #expect(LevelScale.color(for: .init(clamping: 10), scheme: .dark) == Color(hex: 0xE08A72))
}

@Test func levelScaleMidpointIsSand() {
    let mid = LevelScale.color(for: .init(clamping: 5), scheme: .dark)
    #expect(mid != Color(hex: 0x4FC3B5))
    #expect(mid != Color(hex: 0xE08A72))
}

@Test func themeTextTokens() {
    #expect(Theme.text(.dark) == Color(hex: 0xF2F4F3))
    #expect(Theme.text(.light) == Color(hex: 0x0F1F24))
    #expect(Theme.accent(.light) == Color(hex: 0x1F8F82))
}
