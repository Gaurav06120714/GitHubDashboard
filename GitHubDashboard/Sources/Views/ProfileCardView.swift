import SwiftUI

struct ProfileCardView: View {
    @EnvironmentObject var service: GitHubService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = service.user {
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: user.avatarUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name ?? user.login)
                            .font(.headline)
                            .lineLimit(1)
                        Text("@\(user.login)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { service.logout() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Sign Out")
                }

                Divider()

                HStack(spacing: 0) {
                    statItem(value: user.publicRepos, label: "Repos")
                    Divider().frame(height: 28)
                    statItem(value: user.followers, label: "Followers")
                    Divider().frame(height: 28)
                    statItem(value: user.following, label: "Following")
                }
            } else if service.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading profile...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No profile data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(.subheadline, design: .rounded).bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
