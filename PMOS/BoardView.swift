import SwiftUI

struct BoardView: View {
    @EnvironmentObject var store: PMStore
    @State private var showDone = false

    private var buckets: [(String, [BoardTask])] {
        let visible = store.boardTasks.filter { showDone || !$0.isDone }
        let grouped = Dictionary(grouping: visible) { $0.bucket ?? "Other" }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Toggle(isOn: $showDone.animation(.spring(duration: 0.3))) {
                    Text("Show completed")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .tint(Theme.accent)
                .glassCard(padding: 14)

                ForEach(buckets, id: \.0) { pair in
                    BucketSection(name: pair.0, tasks: pair.1)
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
        }
        .refreshable { await store.refresh() }
    }
}

struct BucketSection: View {
    let name: String
    let tasks: [BoardTask]

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
                    TaskRow(item: t)
                }
            }
        }
    }
}

struct TaskRow: View {
    @EnvironmentObject var store: PMStore
    let item: BoardTask

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
                    .foregroundStyle(item.isDone ? .secondary : .white)
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
        }
        .glassCard(padding: 12)
    }
}
