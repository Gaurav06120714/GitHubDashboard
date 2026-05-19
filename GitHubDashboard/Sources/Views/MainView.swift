import SwiftUI

struct MainView: View {
    @EnvironmentObject var service: GitHubService

    var body: some View {
        VStack(spacing: 12) {
            // Error banner
            if let error = service.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Retry") {
                        Task { await service.loadAll() }
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderless)
                    Button(action: { service.error = nil }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Top 3 cards
            HStack(spacing: 12) {
                ProfileCardView()
                TodayCardView()
                StreakCardView()
            }
            .frame(height: 120)

            // Bottom split
            HStack(alignment: .top, spacing: 12) {
                ContributionGraphView()
                    .frame(maxWidth: .infinity)

                CreateRepoView()
                    .frame(width: 260)
            }
        }
        .padding(16)
        .frame(minWidth: 900, minHeight: 600)
        .task {
            if service.user == nil {
                await service.loadAll()
            }
        }
    }
}

// MARK: - Card Style Modifier

extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
