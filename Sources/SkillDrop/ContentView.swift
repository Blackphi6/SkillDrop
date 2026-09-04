import SwiftUI

struct ContentView: View {
    @State private var urlText = ""
    @State private var selected: Set<String> = Set(AgentTarget.selectable.map(\.id))
    @State private var logText = L10n.t("log_hint")
    @State private var isInstalling = false
    @State private var lastSkills: [String] = []
    @State private var errorMessage: String?

    private let installer = SkillInstaller()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            urlField
            agentToggles
            actionRow
            logPanel
        }
        .padding(28)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SkillDrop")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            Text(L10n.t("subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var urlField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("url_label"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(L10n.t("url_placeholder"), text: $urlText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14, design: .monospaced))
                .disabled(isInstalling)
        }
    }

    private var agentToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("targets_label"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ForEach(AgentTarget.selectable) { agent in
                    Toggle(agent.displayName, isOn: Binding(
                        get: { selected.contains(agent.id) },
                        set: { on in
                            if on { selected.insert(agent.id) } else { selected.remove(agent.id) }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .disabled(isInstalling)
                }
            }
            Text(L10n.t("targets_note"))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                Task { await runInstall() }
            } label: {
                HStack(spacing: 8) {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(isInstalling ? L10n.t("installing") : L10n.t("install"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isInstalling || urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selected.isEmpty)
            .keyboardShortcut(.defaultAction)

            if !lastSkills.isEmpty {
                Text(L10n.tf("installed_skills", lastSkills.joined(separator: ", ")))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("log_label"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            ScrollView {
                Text(logText)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(minHeight: 180)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .textBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }
        }
    }

    @MainActor
    private func runInstall() async {
        errorMessage = nil
        isInstalling = true
        logText = ""
        lastSkills = []
        let targets = AgentTarget.selectable.filter { selected.contains($0.id) }
        let input = urlText
        let installer = self.installer
        do {
            let result = try await Task.detached {
                try installer.install(input: input, targets: targets)
            }.value
            lastSkills = result.skillNames
            logText = result.log + "\n\n" + L10n.t("log_ready")
        } catch {
            errorMessage = error.localizedDescription
            if logText.isEmpty {
                logText = error.localizedDescription
            } else {
                logText += "\n\n" + L10n.tf("error_prefix", error.localizedDescription)
            }
        }
        isInstalling = false
    }
}

#Preview {
    ContentView()
        .frame(width: 560, height: 560)
}
