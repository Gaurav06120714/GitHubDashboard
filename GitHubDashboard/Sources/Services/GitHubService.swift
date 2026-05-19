import Foundation
import SwiftUI

@MainActor
final class GitHubService: ObservableObject {
    @Published var user: GitHubUser?
    @Published var repos: [GitHubRepo] = []
    @Published var contributions: [ContributionDay] = []
    @Published var todayCommits: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalContributions: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isAuthenticated: Bool = false

    private let baseURL = "https://api.github.com"
    private let graphqlURL = "https://api.github.com/graphql"

    init() {
        isAuthenticated = KeychainHelper.shared.token != nil
    }

    var token: String? {
        get { KeychainHelper.shared.token }
        set {
            KeychainHelper.shared.token = newValue
            isAuthenticated = newValue != nil
        }
    }

    func authenticate(token: String) async {
        isLoading = true
        error = nil
        // Validate by fetching user
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let url = URL(string: "\(baseURL)/user")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                self.token = trimmed
                await loadAll()
            } else {
                error = "Invalid token. Please check your Personal Access Token and required scopes."
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadAll() async {
        guard let token = token else { return }
        isLoading = true
        error = nil

        do {
            async let userResult = loadUser()
            async let reposResult = loadRepos()

            let (fetchedUser, fetchedRepos) = try await (userResult, reposResult)
            self.user = fetchedUser
            self.repos = fetchedRepos

            // Load contributions using GraphQL
            await loadContributions(login: fetchedUser.login, token: token)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadUser() async throws -> GitHubUser {
        guard let token = token else { throw AppError.noToken }
        let url = URL(string: "\(baseURL)/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        let decoder = JSONDecoder()
        return try decoder.decode(GitHubUser.self, from: data)
    }

    func loadRepos() async throws -> [GitHubRepo] {
        guard let token = token else { throw AppError.noToken }
        let url = URL(string: "\(baseURL)/user/repos?sort=updated&per_page=20")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        let decoder = JSONDecoder()
        return try decoder.decode([GitHubRepo].self, from: data)
    }

    func loadContributions(login: String, token: String) async {
        let query = """
        {
          "query": "{ user(login: \\"\\(login)\\") { contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { contributionCount date } } } } } }"
        }
        """

        guard let url = URL(string: graphqlURL),
              let bodyData = query.data(using: .utf8) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.httpBody = bodyData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GraphQLResponse.self, from: data)

            if let calendar = response.data?.user?.contributionsCollection.contributionCalendar {
                totalContributions = calendar.totalContributions

                var days: [ContributionDay] = []
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(identifier: "UTC")

                for week in calendar.weeks {
                    for day in week.contributionDays {
                        if let date = formatter.date(from: day.date) {
                            days.append(ContributionDay(date: date, count: day.contributionCount))
                        }
                    }
                }

                days.sort { $0.date < $1.date }
                contributions = days

                // Compute today's commits
                let today = Calendar.current.startOfDay(for: Date())
                todayCommits = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.count ?? 0

                // Compute streaks
                computeStreaks(days: days)
            }
        } catch {
            // Non-fatal: contributions failed but app still works
            self.error = "Could not load contributions: \(error.localizedDescription)"
        }
    }

    private func computeStreaks(days: [ContributionDay]) {
        let sorted = days.sorted { $0.date > $1.date } // newest first
        var current = 0
        let today = Calendar.current.startOfDay(for: Date())

        for (index, day) in sorted.enumerated() {
            let dayDate = Calendar.current.startOfDay(for: day.date)
            let expectedDate = Calendar.current.date(byAdding: .day, value: -index, to: today)!
            let expectedStart = Calendar.current.startOfDay(for: expectedDate)
            if dayDate == expectedStart && day.count > 0 {
                current += 1
            } else if dayDate == expectedStart && day.count == 0 {
                break
            } else {
                break
            }
        }
        currentStreak = current

        // Longest streak
        var longest = 0
        var running = 0
        for day in days.sorted(by: { $0.date < $1.date }) {
            if day.count > 0 {
                running += 1
                longest = max(longest, running)
            } else {
                running = 0
            }
        }
        longestStreak = longest
    }

    func createRepo(name: String, description: String, isPrivate: Bool, addReadme: Bool) async throws {
        guard let token = token else { throw AppError.noToken }
        let url = URL(string: "\(baseURL)/user/repos")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateRepoRequest(name: name, description: description, isPrivate: isPrivate, autoInit: addReadme)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        // Refresh repos list
        repos = try await loadRepos()
    }

    func logout() {
        token = nil
        user = nil
        repos = []
        contributions = []
        todayCommits = 0
        currentStreak = 0
        longestStreak = 0
        totalContributions = 0
        error = nil
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401: throw AppError.unauthorized
        case 403: throw AppError.forbidden
        case 404: throw AppError.notFound
        case 422: throw AppError.validationFailed
        default: throw AppError.httpError(http.statusCode)
        }
    }
}

enum AppError: LocalizedError {
    case noToken
    case unauthorized
    case forbidden
    case notFound
    case validationFailed
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noToken: return "No authentication token found."
        case .unauthorized: return "Invalid or expired token."
        case .forbidden: return "Access forbidden. Check token scopes."
        case .notFound: return "Resource not found."
        case .validationFailed: return "Validation failed. Repository name may already exist."
        case .httpError(let code): return "Server error (HTTP \(code))."
        }
    }
}
