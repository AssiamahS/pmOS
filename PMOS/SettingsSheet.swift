import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var store: PMStore
    @Environment(\.dismiss) private var dismiss
    @State private var testResult: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SERVER")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .kerning(1.2)
                            TextField("http://100.x.x.x:8796", text: store.$serverURL)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.white)
                                .font(.body.monospaced())
                            Text("The pm-api on your Mac, reachable over Tailscale.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("API KEY (OPTIONAL)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .kerning(1.2)
                            SecureField("X-PM-Key", text: store.$apiKey)
                                .foregroundStyle(.white)
                            Text("Only needed if ~/.config/pm/api-key exists on the Mac.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .glassCard()

                        Button {
                            Task {
                                await store.refresh()
                                testResult = store.lastError == nil
                                    ? "Connected — \(store.projects.count) project(s), \(store.boardTasks.count) task(s)."
                                    : store.lastError
                            }
                        } label: {
                            Label("Test connection", systemImage: "bolt.horizontal.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        if let result = testResult {
                            Text(result)
                                .font(.footnote)
                                .foregroundStyle(store.lastError == nil ? Theme.mint : Theme.amber)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassCard(padding: 14)
                        }

                        if let sync = store.lastSync {
                            Text("Last sync \(sync.formatted(date: .omitted, time: .standard))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
