import SwiftUI

struct TodayCardView: View {
    @EnvironmentObject var service: GitHubService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Today")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(service.isLoading ? .degrees(360) : .degrees(0))
                        .animation(service.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: service.isLoading)
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(service.todayCommits)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("contributions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Label("Commits today", systemImage: "arrow.triangle.branch")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let user = service.user {
                    Label("Public Repos: \(user.publicRepos)", systemImage: "folder")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }

    private func refresh() {
        Task {
            await service.loadAll()
        }
    }
}
