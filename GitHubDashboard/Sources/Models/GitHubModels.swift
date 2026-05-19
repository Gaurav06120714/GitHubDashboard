import SwiftUI

struct GitHubUser: Codable {
    let login: String
    let name: String?
    let avatarUrl: String
    let publicRepos: Int
    let followers: Int
    let following: Int
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case login, name, bio, followers, following
        case avatarUrl = "avatar_url"
        case publicRepos = "public_repos"
    }
}

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let stargazersCount: Int
    let language: String?
    let updatedAt: String
    let isPrivate: Bool
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case stargazersCount = "stargazers_count"
        case updatedAt = "updated_at"
        case isPrivate = "private"
        case htmlUrl = "html_url"
    }
}

struct ContributionDay: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var color: Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1...3: return Color.green.opacity(0.3)
        case 4...6: return Color.green.opacity(0.6)
        case 7...9: return Color.green.opacity(0.8)
        default: return Color.green
        }
    }
}

struct CreateRepoRequest: Codable {
    let name: String
    let description: String
    let isPrivate: Bool
    let autoInit: Bool

    enum CodingKeys: String, CodingKey {
        case name, description
        case isPrivate = "private"
        case autoInit = "auto_init"
    }
}

// GraphQL response models
struct GraphQLResponse: Codable {
    let data: GraphQLData?
    let errors: [GraphQLError]?
}

struct GraphQLData: Codable {
    let user: GraphQLUser?
}

struct GraphQLError: Codable {
    let message: String
}

struct GraphQLUser: Codable {
    let contributionsCollection: ContributionsCollection
}

struct ContributionsCollection: Codable {
    let contributionCalendar: ContributionCalendar
}

struct ContributionCalendar: Codable {
    let totalContributions: Int
    let weeks: [ContributionWeek]
}

struct ContributionWeek: Codable {
    let contributionDays: [ContributionDayRaw]
}

struct ContributionDayRaw: Codable {
    let contributionCount: Int
    let date: String
}
