import EbbCore
import Foundation

/// Правдоподобные данные за 30 дней для скриншотов и превью. Детерминированные.
enum DemoData {
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    private static let thoughts = [
        "Не успею сдать отчёт к пятнице", "Не успею сдать работу вовремя", "Что-то не так с сердцем",
        "Денег не хватит до конца месяца", "Хватит ли денег до конца месяца", "Что скажут на завтрашней встрече",
        "Вдруг опоздаю на рейс", "Кажется, я всё делаю медленнее других",
    ]
    private static let fears = [
        "провалю презентацию", "меня уволят", "это что-то серьёзное", "не хватит на аренду",
        "завалю экзамен", "провалю всё на встрече",
    ]
    private static let triggers = ["общение", "работа", "здоровье", "деньги", "отношения", "не знаю"]

    @MainActor
    static func seed(into store: Store, now: Date) {
        var rng = SeededGenerator(state: 2026)
        let cal = Calendar.current
        var fearCount = 0

        for daysAgo in stride(from: 29, through: 0, by: -1) {
            let dayStart = cal.startOfDay(for: now.addingTimeInterval(Double(-daysAgo) * 86400))
            let entriesToday = daysAgo % 3 == 0 ? 2 : 1
            for n in 0..<entriesToday {
                let hour = n == 0 ? Int.random(in: 9...14, using: &rng) : Int.random(in: 17...22, using: &rng)
                let createdAt = dayStart.addingTimeInterval(Double(hour * 3600 + Int.random(in: 0..<3600, using: &rng)))
                guard createdAt < now else { continue }
                let trend = Double(daysAgo) / 29 * 2.5
                let before = min(9, max(3, Int((Double.random(in: 3.5...7.5, using: &rng) + trend).rounded())))
                let trigger = triggers[Int.random(in: 0..<triggers.count, using: &rng)]
                let thought = Bool.random(using: &rng) || before >= 6 ? thoughts[Int.random(in: 0..<thoughts.count, using: &rng)] : nil
                var fear: String? = nil
                if fearCount < 12, before >= 5, Int.random(in: 0..<3, using: &rng) == 0 {
                    fear = fears[fearCount % fears.count]
                    fearCount += 1
                }
                let (coping, delta): (CopingMethod, Int) = {
                    switch Int.random(in: 0..<10, using: &rng) {
                    case 0...3: return (.practice(.breathing), Int.random(in: -4 ... -2, using: &rng))
                    case 4...5: return (.ownAction("гулял"), Int.random(in: -3 ... -2, using: &rng))
                    case 6: return (.practice(.thoughtCheck), Int.random(in: -3 ... -1, using: &rng))
                    case 7...8: return (.ownAction("играл"), Int.random(in: -1 ... 0, using: &rng))
                    default: return (.ownAction("работал"), Int.random(in: -1 ... 1, using: &rng))
                    }
                }()
                let after = AnxietyLevel(clamping: before + delta)
                let afterAt = createdAt.addingTimeInterval(Double(Int.random(in: 180...2400, using: &rng)))
                let entry = Entry(createdAt: createdAt, levelBefore: .init(clamping: before), thought: thought, trigger: trigger, fear: fear, coping: coping, levelAfter: after, afterAt: afterAt)
                store.upsert(entry)

                if case .ownAction(let name) = coping { store.touchOwnAction(name, at: createdAt) }
                if case .practice(let kind) = coping {
                    let details: PracticeDetails = kind == .breathing
                        ? .breathing(pattern: .calm46, plannedSeconds: 180, actualSeconds: 180)
                        : .thoughtCheck(thought: thought ?? "", beliefBefore: 80, evidenceFor: "Сроки правда сжатые", evidenceAgainst: "Прошлые три отчёта сдал вовремя", toFriend: "Начни с плана", beliefAfter: 40)
                    store.add(PracticeSession(entryID: entry.id, kind: kind, startedAt: createdAt.addingTimeInterval(60), endedAt: createdAt.addingTimeInterval(240), details: details))
                }

                if fear != nil {
                    var checks = FearCheckScheduler.checks(for: entry)
                    let answerDay3 = checks[0].dueAt.addingTimeInterval(3600)
                    if answerDay3 < now {
                        let outcome: FearCheck.Outcome = fearCount == 3 ? .happenedBad : (fearCount == 6 || fearCount == 9) ? .happenedTolerable : .didNotHappen
                        checks = FearCheckScheduler.answer(checks[0], outcome: outcome, in: checks, at: answerDay3)
                        if checks.count == 2, checks[1].dueAt.addingTimeInterval(3600) < now {
                            checks = FearCheckScheduler.answer(checks[1], outcome: .didNotHappen, in: checks, at: checks[1].dueAt.addingTimeInterval(3600))
                        }
                    }
                    store.replaceFearChecks(forEntry: entry.id, with: checks)
                }
            }

            if daysAgo < 25 {
                store.upsert(DailyHabits(
                    day: DayKey(dayStart, calendar: cal),
                    sleepHours: [5.5, 6, 6.5, 7, 7.5, 8][Int.random(in: 0..<6, using: &rng)],
                    moved: Int.random(in: 0..<3, using: &rng) != 0,
                    caffeineServings: Int.random(in: 0...3, using: &rng),
                    alcohol: Int.random(in: 0..<6, using: &rng) == 0
                ))
            }
        }

        // Открытая запись: своё действие сорок минут назад, замера «после» ещё нет.
        store.upsert(Entry(createdAt: now.addingTimeInterval(-40 * 60), levelBefore: .init(clamping: 7), thought: "Не успею сдать отчёт к пятнице", trigger: "общение", fear: "провалю презентацию", coping: .ownAction("гулял")))
        store.touchOwnAction("гулял", at: now)
        store.touchOwnAction("звонил другу", at: now.addingTimeInterval(-5 * 86400))

        // Вопрос оглядки, срок которого наступил сегодня.
        let dueEntry = Entry(createdAt: now.addingTimeInterval(-3 * 86400 - 1800), levelBefore: .init(clamping: 8), thought: "Что скажут на завтрашней встрече", trigger: "общение", fear: "провалю презентацию", coping: .practice(.breathing), levelAfter: .init(clamping: 4), afterAt: now.addingTimeInterval(-3 * 86400))
        store.upsert(dueEntry)
        store.replaceFearChecks(forEntry: dueEntry.id, with: FearCheckScheduler.checks(for: dueEntry))

        store.upsert(LadderStep(title: "Задать вопрос на общей встрече", note: "Один короткий вопрос", order: 0, completions: [now.addingTimeInterval(-6 * 86400)]))
        store.upsert(LadderStep(title: "Записаться к врачу", order: 1))
        store.upsert(LadderStep(title: "Выступить с коротким докладом", order: 2))
        store.add(DeferredThought(text: "А если отчёт не примут?", deferredAt: now.addingTimeInterval(-3 * 3600)))
    }
}
