import SwiftUI

struct BoardView: View {
    @EnvironmentObject var store: PMStore
    @State private var showDone = false
    @State private var note = ""
    @State private var capturing = false
    @State private var editing: BoardTask?

    // Buckets with the nearest deadline float to the top; tasks inside a
    // bucket sort deadline-first so what's due reads at a glance.
    private var buckets: [(String, [BoardTask])] {
        let visible = store.boardTasks.filter { showDone || !$0.isDone }
        let grouped = Dictionary(grouping: visible) { $0.bucket ?? "Other" }
        let sortedTasks = grouped.mapValues { ts in
            ts.sorted { ($0.deadline ?? "9999", $0.id) < ($1.deadline ?? "9999", $1.id) }
        }
        return sortedTasks.sorted {
            let a = $0.value.first?.deadline ?? "9999"
            let b = $1.value.first?.deadline ?? "9999"
            return a == b ? $0.key < $1.key : a < b
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                captureBar

                Toggle(isOn: $showDone.animation(.spring(duration: 0.3))) {
                    Text("Show completed")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .tint(Theme.accent)
                .glassCard(padding: 14)

                ForEach(buckets, id: \.0) { pair in
                    BucketSection(name: pair.0, tasks: pair.1) { editing = $0 }
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
        }
        .refreshable { await store.refresh() }
        .sheet(item: $editing) { TaskEditSheet(item: $0) }
    }

    private var captureBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.pencil")
                .foregroundStyle(Theme.accent)
            TextField("Note it… \"call Mr. Bond by friday\"", text: $note, axis: .vertical)
                .foregroundStyle(.white)
                .submitLabel(.done)
                .onSubmit(capture)
            if capturing {
                ProgressView().tint(Theme.accent)
            } else if !note.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: capture) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .glassCard(padding: 14)
    }

    private func capture() {
        let text = note.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !capturing else { return }
        capturing = true
        Task {
            if await store.capture(text) { note = "" }
            capturing = false
        }
    }
}

struct BucketSection: View {
    let name: String
    let tasks: [BoardTask]
    var onEdit: (BoardTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.violet)
                    .kerning(1.2)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            VStack(spacing: 8) {
                ForEach(tasks) { t in
                    TaskRow(item: t, onEdit: onEdit)
                }
            }
        }
    }
}

struct TaskRow: View {
    @EnvironmentObject var store: PMStore
    let item: BoardTask
    var onEdit: (BoardTask) -> Void = { _ in }

    private var statusColor: Color {
        switch item.status {
        case "done": return Theme.mint
        case "blocked": return Theme.red
        case "paused": return Theme.amber
        case "backlog": return .gray
        default: return Theme.accent
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task { _ = await store.toggleTask(item) }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(item.isDone ? Theme.mint : Color.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(item.isDone ? Color.secondary : Color.white)
                    .strikethrough(item.isDone, color: .secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if item.status != "active" && !item.isDone {
                        Text(item.status)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(statusColor)
                    }
                    if let dl = item.deadline {
                        Label(String(dl.prefix(10)), systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .glassCard(padding: 12)
        .contentShape(Rectangle())
        .onTapGesture { onEdit(item) }
    }
}
