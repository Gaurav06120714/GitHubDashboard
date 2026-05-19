import SwiftUI

struct StreakCardView: View {
    @EnvironmentObject var service: GitHubService

    private var streakRatio: Double {
        guard service.longestStreak > 0 else { return 0 }
        return min(Double(service.currentStreak) / Double(service.longestStreak), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Streak")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("🔥")
                    .font(.title2)
                Text("\(service.currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Longest: \(service.longestStreak)d")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Total this year: \(service.totalContributions)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * streakRatio, height: 6)
                            .animation(.easeInOut, value: streakRatio)
                    }
                }
                .frame(height: 6)
            }
        }
        .cardStyle()
    }
}
