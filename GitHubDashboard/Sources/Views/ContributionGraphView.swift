import SwiftUI

struct ContributionGraphView: View {
    @EnvironmentObject var service: GitHubService

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 2
    private let columns = 52
    private let rows = 7

    // Build a 52x7 grid from contributions
    private var grid: [[ContributionDay?]] {
        let today = Date()
        let calendar = Calendar.current

        // Find the start of the week 52 weeks ago
        let startDate: Date = {
            let daysBack = (52 * 7) - 1
            let raw = calendar.date(byAdding: .day, value: -daysBack, to: today)!
            // Align to Sunday (weekday 1)
            let weekday = calendar.component(.weekday, from: raw)
            let offset = weekday - 1 // days since Sunday
            return calendar.date(byAdding: .day, value: -offset, to: raw) ?? raw
        }()

        // Map contributions by date string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        var contributionMap: [String: ContributionDay] = [:]
        for day in service.contributions {
            let key = formatter.string(from: day.date)
            contributionMap[key] = day
        }

        var grid: [[ContributionDay?]] = Array(repeating: Array(repeating: nil, count: rows), count: columns)

        for col in 0..<columns {
            for row in 0..<rows {
                let dayOffset = col * 7 + row
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    if date <= today {
                        let key = formatter.string(from: date)
                        if let day = contributionMap[key] {
                            grid[col][row] = day
                        } else {
                            grid[col][row] = ContributionDay(date: date, count: 0)
                        }
                    }
                }
            }
        }

        return grid
    }

    private var monthLabels: [(String, Int)] {
        let calendar = Calendar.current
        let today = Date()
        let daysBack = (52 * 7) - 1
        let rawStart = calendar.date(byAdding: .day, value: -daysBack, to: today)!
        let weekday = calendar.component(.weekday, from: rawStart)
        let startDate = calendar.date(byAdding: .day, value: -(weekday - 1), to: rawStart) ?? rawStart

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var labels: [(String, Int)] = []
        var lastMonth = -1

        for col in 0..<columns {
            if let date = calendar.date(byAdding: .day, value: col * 7, to: startDate) {
                let month = calendar.component(.month, from: date)
                if month != lastMonth {
                    labels.append((monthFormatter.string(from: date), col))
                    lastMonth = month
                }
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text("Contributions")
                .font(.headline)

            // Heatmap
            heatmapSection

            Divider()

            // Repos list
            reposList
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            HStack(spacing: 0) {
                // Offset for day labels
                Text("   ")
                    .font(.system(size: 9))
                    .frame(width: 20)

                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(width: CGFloat(columns) * (cellSize + cellSpacing), height: 14)

                    ForEach(monthLabels, id: \.1) { label, col in
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .offset(x: CGFloat(col) * (cellSize + cellSpacing))
                    }
                }
            }

            HStack(alignment: .top, spacing: 4) {
                // Day labels
                VStack(spacing: cellSpacing) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day.prefix(1))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(width: 10, height: cellSize)
                    }
                }

                // Grid
                HStack(spacing: cellSpacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<rows, id: \.self) { row in
                                if let day = grid[col][row] {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(day.color)
                                        .frame(width: cellSize, height: cellSize)
                                        .help("\(formattedDate(day.date)): \(day.count) contribution\(day.count == 1 ? "" : "s")")
                                } else {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                ForEach([0.0, 0.3, 0.6, 0.8, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(opacity == 0 ? Color.gray.opacity(0.15) : Color.green.opacity(opacity))
                        .frame(width: cellSize, height: cellSize)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var reposList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Repositories")
                .font(.subheadline.bold())

            if service.repos.isEmpty && service.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading repositories...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(service.repos) { repo in
                            RepoRowView(repo: repo)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    NSWorkspace.shared.open(URL(string: repo.htmlUrl)!)
                                }

                            if repo.id != service.repos.last?.id {
                                Divider()
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

struct RepoRowView: View {
    let repo: GitHubRepo

    private let languageColors: [String: Color] = [
        "Swift": .orange,
        "Python": .blue,
        "JavaScript": .yellow,
        "TypeScript": .blue,
        "Kotlin": .purple,
        "Java": .red,
        "Go": .cyan,
        "Rust": .orange,
        "Ruby": .red,
        "C++": .pink,
        "C": .gray,
        "HTML": .orange,
        "CSS": .blue,
        "Shell": .green,
        "Dart": .cyan
    ]

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        if let date = ISO8601DateFormatter().date(from: repo.updatedAt) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return repo.updatedAt
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if repo.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(repo.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }

                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if let lang = repo.language {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(languageColors[lang] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(lang)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 2) {
                    Image(systemName: "star")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(repo.stargazersCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(relativeDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color.primary.opacity(0.001)) // make entire row tappable
    }
}
