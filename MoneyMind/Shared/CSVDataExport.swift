import Foundation

enum CSVDataExport {
    static func makeAllTables(
        transactions: [Transaction],
        categories: [TransactionCategory],
        budgets: [Budget],
        goals: [SavingsGoal],
        contributions: [GoalContribution]
    ) -> String {
        var lines: [String] = []
        lines.append("# MoneyMind data export")
        lines.append("# Generated: \(isoNow())")
        lines.append("")

        lines.append("## categories")
        lines.append("id,name,icon,colorHex,type,createdAt")
        for c in categories.sorted(by: { $0.id < $1.id }) {
            lines.append([
                "\(c.id)",
                csvEscape(c.name),
                csvEscape(c.icon),
                csvEscape(c.colorHex),
                csvEscape(c.type.rawValue),
                iso(c.createdAt),
            ].joined(separator: ","))
        }
        lines.append("")

        lines.append("## transactions")
        lines.append("id,amount,note,date,type,categoryId,categoryName,categoryIcon,categoryColorHex,createdAt")
        for t in transactions.sorted(by: { $0.id < $1.id }) {
            lines.append([
                "\(t.id)",
                "\(t.amount)",
                csvEscape(t.note),
                iso(t.date),
                csvEscape(t.type.rawValue),
                "\(t.categoryId)",
                csvEscape(t.categoryName),
                csvEscape(t.categoryIcon),
                csvEscape(t.categoryColorHex),
                iso(t.createdAt),
            ].joined(separator: ","))
        }
        lines.append("")

        lines.append("## budgets")
        lines.append("id,categoryId,amount,createdAt")
        for b in budgets.sorted(by: { $0.id < $1.id }) {
            lines.append([
                "\(b.id)",
                "\(b.categoryId)",
                "\(b.amount)",
                iso(b.createdAt),
            ].joined(separator: ","))
        }
        lines.append("")

        lines.append("## savings_goals")
        lines.append("id,name,icon,colorHex,targetAmount,targetDate,note,createdAt")
        for g in goals.sorted(by: { $0.id < $1.id }) {
            lines.append([
                "\(g.id)",
                csvEscape(g.name),
                csvEscape(g.icon),
                csvEscape(g.colorHex),
                "\(g.targetAmount)",
                g.targetDate.map { iso($0) } ?? "",
                csvEscape(g.note),
                iso(g.createdAt),
            ].joined(separator: ","))
        }
        lines.append("")

        lines.append("## goal_contributions")
        lines.append("id,goalId,amount,date,note,createdAt")
        for c in contributions.sorted(by: { $0.id < $1.id }) {
            lines.append([
                "\(c.id)",
                "\(c.goalId)",
                "\(c.amount)",
                iso(c.date),
                csvEscape(c.note),
                iso(c.createdAt),
            ].joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        } else {
            value
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static func iso(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static func isoNow() -> String {
        isoFormatter.string(from: Date())
    }
}
