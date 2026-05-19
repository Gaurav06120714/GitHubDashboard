import SwiftUI

struct TokenSetupView: View {
    @EnvironmentObject var service: GitHubService
    @State private var tokenInput: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon + Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 72, height: 72)
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Text("Connect GitHub")
                        .font(.title.bold())

                    Text("Enter your Personal Access Token")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Instructions box
                VStack(alignment: .leading, spacing: 6) {
                    Text("How to generate a token:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Text("GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Text("Required scopes:")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Text("repo, read:user, user")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Token field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personal Access Token")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .focused($fieldFocused)
                }

                // Error
                if let error = service.error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Buttons
                VStack(spacing: 10) {
                    Button(action: connect) {
                        if service.isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Connecting...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Connect")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isLoading)
                    .keyboardShortcut(.return, modifiers: [])

                    Button("Generate Token on GitHub") {
                        NSWorkspace.shared.open(URL(string: "https://github.com/settings/tokens")!)
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
            .padding(32)
            .frame(width: 420)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)

            Spacer()
        }
        .frame(width: 500, height: 520)
        .onAppear { fieldFocused = true }
    }

    private func connect() {
        let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await service.authenticate(token: trimmed)
        }
    }
}
