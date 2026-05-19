# GitHubDashboard

A native macOS app to monitor your GitHub activity at a glance — contributions, streaks, top repos, and quick repo creation, all in one clean dashboard.

## Features

- **Live Contribution Graph** — GitHub-style heatmap of your contributions for the year
- **Streak Tracking** — Current and longest contribution streaks with daily count
- **Profile Overview** — Avatar, username, follower count, and public repo count
- **Today's Activity** — Highlights today's contribution count prominently
- **Create Repo** — Create a new GitHub repository directly from the dashboard with one click
- **Secure Token Storage** — GitHub Personal Access Token stored safely in macOS Keychain

## Requirements

- macOS 13 or later
- GitHub Personal Access Token with `repo` and `read:user` scopes

## Getting Started

```bash
git clone https://github.com/Gaurav06120714/GitHubDashboard.git
cd GitHubDashboard
swift build -c release
.build/release/GitHubDashboard
```

## Generate a GitHub Token

1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens/new)
2. Select scopes: `repo`, `read:user`
3. Copy and paste into the app on first launch

## Built With

- Swift + SwiftUI
- AppKit (NSWindow, NSStatusItem)
- GitHub REST API + GraphQL API
- Swift Package Manager

## Author

**Gaurav Ganesh Teegulla**  
[github.com/Gaurav06120714](https://github.com/Gaurav06120714)
