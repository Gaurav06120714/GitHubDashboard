// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitHubDashboard",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GitHubDashboard",
            path: "GitHubDashboard/Sources",
            resources: [.process("../Resources")]
        )
    ]
)
