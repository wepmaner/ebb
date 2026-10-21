import Testing
@testable import EbbCore

@Test func levelClampsOutOfRange() {
    #expect(AnxietyLevel(clamping: -3).value == 0)
    #expect(AnxietyLevel(clamping: 14).value == 10)
}

@Test(arguments: [(0, "спокойно"), (2, "спокойно"), (3, "слегка"), (5, "заметно"), (7, "сильно"), (9, "очень"), (10, "очень")])
func levelLabels(value: Int, label: String) {
    #expect(AnxietyLevel(clamping: value).label == label)
}
