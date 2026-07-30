import SwiftUI

struct TaskEditSheet: View {
    @EnvironmentObject var store: PMStore
    @Environment(\.dismiss) private var dismiss

    let item: BoardTask

    @State private var title = ""
    @State private var notes = ""
    @State private var status = "active"
    @State private var hasDeadline = false
    @State private var deadline = Date.now
    @State private var saving = false

    private static let statuses = ["active", "paused", "blocked", "backlog", "done"]

    private static let wireFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f
    }()

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !saving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("TASK")
                            TextField("Title", text: $title, axis: .vertical)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("STATUS")
                            Picker("Status", selection: $status) {
                                ForEach(Self.statuses, id: \.self) { Text($0.capitalized).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()

                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasDeadline.animation(.spring(duration: 0.3))) {
                                fieldLabel("DEADLINE")
                            }
                            .tint(Theme.accent)
                            if hasDeadline {
                                DatePicker("Due", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.graphical)
                                    .tint(Theme.accent)
                            }
                        }
                        .glassCard()

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("NOTES")
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(2...6)
                                .foregroundStyle(.white)
                        }
                        .glassCard()

                        Button(action: save) {
                            HStack {
                                if saving { ProgressView().tint(.white) }
                                Text(saving ? "Saving…" : "Save changes")
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
            .navigationTitle("Edit task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            title = item.title
            notes = item.notes ?? ""
            status = Self.statuses.contains(item.status) ? item.status : "active"
            if let dl = item.deadline, let d = Self.wireFormat.date(from: String(dl.prefix(16))) {
                hasDeadline = true
                deadline = d
            }
        }
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
            let ok = await store.editTask(
                id: item.id,
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes,
                deadline: hasDeadline ? Self.wireFormat.string(from: deadline) : nil,
                status: status
            )
            saving = false
            if ok { dismiss() }
        }
    }
}
