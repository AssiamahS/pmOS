import SwiftUI

struct NeedBySheet: View {
    @EnvironmentObject var store: PMStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var project = ""
    @State private var newProject = ""
    @State private var due = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var notes = ""
    @State private var createTask = true
    @State private var saving = false

    private var projectKeys: [String] { store.projects.map(\.key) }
    private var resolvedProject: String {
        project == "__new__" ? newProject.trimmingCharacters(in: .whitespaces).lowercased() : project
    }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !resolvedProject.isEmpty && !saving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("WHAT NEEDS TO SHIP")
                            TextField("Deliverable", text: $title, axis: .vertical)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("PROJECT")
                            Picker("Project", selection: $project) {
                                Text("Choose…").tag("")
                                ForEach(projectKeys, id: \.self) { Text($0).tag($0) }
                                Text("New project…").tag("__new__")
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)
                            if project == "__new__" {
                                TextField("new project key (e.g. ccwatch)", text: $newProject)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("NEEDED BY")
                            DatePicker("Due", selection: $due, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .tint(Theme.accent)
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("DEFINITION OF DONE")
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(2...5)
                                .foregroundStyle(.white)
                        }
                        .glassCard()

                        Toggle(isOn: $createTask) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add to Claude taskboard")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Creates a task with this deadline so Claude sees it")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Theme.accent)
                        .glassCard()

                        Button(action: save) {
                            HStack {
                                if saving { ProgressView().tint(.white) }
                                Text(saving ? "Committing…" : "Commit deadline")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                canSave ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.1)),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                        }
                        .disabled(!canSave)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Need it by")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { if project.isEmpty { project = projectKeys.first ?? "__new__" } }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .kerning(1.2)
    }

    private func save() {
        saving = true
        Task {
            let ok = await store.needBy(
                project: resolvedProject,
                title: title.trimmingCharacters(in: .whitespaces),
                due: due,
                notes: notes,
                createTask: createTask
            )
            saving = false
            if ok { dismiss() }
        }
    }
}
