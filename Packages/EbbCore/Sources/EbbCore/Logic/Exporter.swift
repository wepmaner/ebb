import Foundation

/// Экспорт дневника для обсуждения с нейросетью: Markdown или JSON с промптом.
public enum Exporter {
    /// Оставляет только то, что попадает в период.
    public static func filtered(_ s: Snapshot, period: Period, now: Date) -> Snapshot {
        var out = s
        out.exportedAt = now
        out.entries = s.entries.filter { period.contains($0.createdAt, now: now) }.sorted { $0.createdAt < $1.createdAt }
        let kept = Set(out.entries.map(\.id))
        out.sessions = s.sessions.filter { session in
            if let id = session.entryID { return kept.contains(id) }
            return period.contains(session.startedAt, now: now)
        }
        out.fearChecks = s.fearChecks.filter { kept.contains($0.entryID) }
        out.habits = s.habits.filter { period.contains($0.day.date(), now: now) }.sorted { $0.day < $1.day }
        out.deferred = s.deferred.filter { period.contains($0.deferredAt, now: now) }
        return out
    }

    public static func json(_ s: Snapshot, period: Period, now: Date, prompt: String) throws -> Data {
        let data = try SnapshotCodec.encode(filtered(s, period: period, now: now))
        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw SnapshotError.corrupted }
        object["prompt"] = prompt
        object["period"] = period.rawValue
        return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }

    public static func markdown(_ s: Snapshot, period: Period, now: Date, prompt: String, calendar: Calendar = .current) -> String {
        let f = filtered(s, period: period, now: now)
        var md = prompt
        md += "\n\n---\n\n# Дневник тревоги · период: \(period.title)\n\n"
        md += summary(f, now: now)
        md += entries(f, calendar: calendar)
        md += sessions(f, calendar: calendar)
        md += fears(f, calendar: calendar)
        md += habits(f)
        md += ladder(f)
        return md
    }

    // MARK: - Разделы

    private static func summary(_ f: Snapshot, now: Date) -> String {
        let methods = Stats.methods(f.entries, period: .all, now: now)
        let fearSummary = Stats.fears(f.fearChecks, entries: f.entries, period: .all, now: now)
        let avg = f.entries.isEmpty ? 0 : Double(f.entries.map(\.levelBefore.value).reduce(0, +)) / Double(f.entries.count)
        var out = "## Сводка\n\n"
        out += "- Записей: \(f.entries.count), средний уровень до: \(fmt(avg))\n"
        for m in methods {
            out += "- \(m.method.displayName): \(m.count) раз, среднее изменение \(fmt(m.averageDelta))\(m.isLowData ? " (мало данных)" : "")\n"
        }
        out += "- Страхов записано: \(fearSummary.feared), отвечено: \(fearSummary.answered), сбылось: \(fearSummary.happened) (терпимо: \(fearSummary.happenedTolerable))\n\n"
        return out
    }

    private static func entries(_ f: Snapshot, calendar: Calendar) -> String {
        var out = "## Записи\n\n"
        if f.entries.isEmpty { return out + "Записей за период нет.\n\n" }
        let byDay = Dictionary(grouping: f.entries) { DayKey($0.createdAt, calendar: calendar) }
        for day in byDay.keys.sorted() {
            out += "### \(day.raw)\n\n"
            for e in byDay[day]!.sorted(by: { $0.createdAt < $1.createdAt }) {
                var parts = [time(e.createdAt, calendar: calendar)]
                parts.append(e.levelAfter.map { "\(e.levelBefore.value) → \($0.value)" } ?? "\(e.levelBefore.value)")
                if let c = e.coping { parts.append(c.displayName) }
                if let t = e.trigger, !t.isEmpty { parts.append(t) }
                if e.hasThought, let thought = e.thought { parts.append("«\(thought)»") }
                if e.hasFear, let fear = e.fear { parts.append("страх: «\(fear)»") }
                if e.closedAt != nil, e.levelAfter == nil { parts.append("закрыта без замера") }
                out += "- " + parts.joined(separator: " · ") + "\n"
            }
            out += "\n"
        }
        return out
    }

    private static func sessions(_ f: Snapshot, calendar: Calendar) -> String {
        var out = "## Практики\n\n"
        if f.sessions.isEmpty { return out + "Практик за период нет.\n\n" }
        for s in f.sessions.sorted(by: { $0.startedAt < $1.startedAt }) {
            out += "- \(DayKey(s.startedAt, calendar: calendar).raw) \(time(s.startedAt, calendar: calendar)) · \(s.kind.title) · \(s.durationSeconds) с"
            switch s.details {
            case .breathing(let p, _, let actual):
                out += " · \(p.title), \(actual) с"
            case .grounding(let see, let touch, let hear, let smell, let taste):
                let all = [see, touch, hear, smell, taste].flatMap { $0 }.filter { !$0.isEmpty }
                if !all.isEmpty { out += " · " + all.joined(separator: ", ") }
            case .thoughtCheck(let thought, let before, let pro, let contra, let friend, let after):
                out += "\n  - мысль: «\(thought)», верил \(before)% → \(after)%\n  - за: \(pro)\n  - против: \(contra)\n  - другу: \(friend)"
            case .deferred:
                out += " · отложена"
            case .muscleRelaxation(let groups, _):
                out += " · групп мышц: \(groups)"
            }
            out += "\n"
        }
        return out + "\n"
    }

    private static func fears(_ f: Snapshot, calendar: Calendar) -> String {
        var out = "## Оглядка\n\n"
        let feared = f.entries.filter(\.hasFear)
        if feared.isEmpty { return out + "Страхов за период не записано.\n\n" }
        for e in feared {
            let checks = f.fearChecks.filter { $0.entryID == e.id }.sorted { $0.dueAt < $1.dueAt }
            let answers = checks.compactMap { c -> String? in
                guard let o = c.outcome else { return nil }
                return "\(c.stage == .day3 ? "3 дня" : "14 дней"): \(outcomeTitle(o))"
            }
            let fear = e.fear ?? ""
            out += "- \(DayKey(e.createdAt, calendar: calendar).raw) · «\(fear)» · " + (answers.isEmpty ? "ответа пока нет" : answers.joined(separator: ", ")) + "\n"
        }
        return out + "\n"
    }

    private static func habits(_ f: Snapshot) -> String {
        var out = "## Привычки\n\n"
        if f.habits.isEmpty { return out + "Привычки за период не отмечались.\n\n" }
        out += "| день | сон, ч | движение | кофеин | алкоголь | своё |\n|---|---|---|---|---|---|\n"
        for h in f.habits {
            let custom = h.custom.filter { $0.value }.keys.sorted().joined(separator: ", ")
            out += "| \(h.day.raw) | \(h.sleepHours.map(fmt) ?? "—") | \(yesNo(h.moved)) | \(h.caffeineServings.map(String.init) ?? "—") | \(yesNo(h.alcohol)) | \(custom) |\n"
        }
        return out + "\n"
    }

    private static func ladder(_ f: Snapshot) -> String {
        var out = "## Лестница\n\n"
        if f.ladder.isEmpty { return out + "Лестница шагов пуста.\n" }
        for step in f.ladder.sorted(by: { $0.order < $1.order }) {
            out += "- \(step.title) · сделано \(step.completions.count) раз" + (step.note.isEmpty ? "" : " · \(step.note)") + "\n"
        }
        return out
    }

    // MARK: - Форматирование

    private static func fmt(_ v: Double) -> String {
        let r = (v * 10).rounded() / 10
        if r == r.rounded() { return String(Int(r)) }
        return String(r).replacingOccurrences(of: ".", with: ",")
    }

    private static func yesNo(_ v: Bool?) -> String {
        guard let v else { return "—" }
        return v ? "да" : "нет"
    }

    private static func time(_ d: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    private static func outcomeTitle(_ o: FearCheck.Outcome) -> String {
        switch o {
        case .didNotHappen: "не случилось"
        case .happenedTolerable: "случилось, терпимо"
        case .happenedBad: "случилось, было плохо"
        case .skipped: "пропущено"
        }
    }
}
