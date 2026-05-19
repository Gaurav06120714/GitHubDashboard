import SwiftUI

struct CreateRepoView: View {
    @EnvironmentObject var service: GitHubService

    @State private var repoName: String = ""
    @State private var repoDescription: String = ""
    @State private var isPrivate: Bool = false
    @State private var addReadme: Bool = true
    @State private var isCreating: Bool = false
    @State private var creationError: String?
    @State private var createdRepoName: String?
    @State private var createdRepoUrl: String?

    private var isNameValid: Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return !repoName.isEmpty && repoName.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private var nameValidationMessage: String? {
        if repoName.isEmpty { return nil }
        if !isNameValid {
            return "Only letters, numbers, hyphens, underscores, and dots allowed."
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New Repository")
                .font(.headline)

            if let createdName = createdRepoName, let createdUrl = createdRepoUrl {
                successView(name: createdName, url: createdUrl)
            } else {
                formView
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .frame(width: 260)
    }

    @ViewBuilder
    private var formView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Repo name
            VStack(alignment: .leading, spacing: 4) {
                Text("Repository name")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                TextField("my-awesome-project", text: $repoName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                if let msg = nameValidationMessage {
                    Text(msg)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description (optional)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                TextField("Short description", text: $repoDescription)
                    .textFieldStyle(.roundedBorder)
            }

            // Visibility picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Visibility")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Picker("Visibility", selection: $isPrivate) {
                    Text("Public").tag(false)
                    Text("Private").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Initialize with README
            Toggle(isOn: $addReadme) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Initialize with README")
                        .font(.caption)
                    Text("Adds a README.md to the repository")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.checkbox)

            // Error
            if let error = creationError {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Create button
            Button(action: createRepo) {
                if isCreating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Creating...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Create Repository", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isNameValid || isCreating)
        }
    }

    @ViewBuilder
    private func successView(name: String, url: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("Repository Created!")
                .font(.subheadline.bold())

            Text(name)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Button("Open in GitHub") {
                    NSWorkspace.shared.open(URL(string: url)!)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("Create Another") {
                    resetForm()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private func createRepo() {
        guard isNameValid else { return }
        isCreating = true
        creationError = nil

        Task {
            do {
                let name = repoName.trimmingCharacters(in: .whitespacesAndNewlines)
                try await service.createRepo(
                    name: name,
                    description: repoDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    isPrivate: isPrivate,
                    addReadme: addReadme
                )
                // Success
                if let login = service.user?.login {
                    createdRepoUrl = "https://github.com/\(login)/\(name)"
                } else {
                    createdRepoUrl = "https://github.com"
                }
                createdRepoName = name
            } catch {
                creationError = error.localizedDescription
            }
            isCreating = false
        }
    }

    private func resetForm() {
        repoName = ""
        repoDescription = ""
        isPrivate = false
        addReadme = true
        createdRepoName = nil
        createdRepoUrl = nil
        creationError = nil
    }
}
