import SwiftUI

struct DeliverableRow: View {
    @EnvironmentObject var store: PMStore
    let deliverable: Deliverable
    var showProject = true

    private var color: Color { Theme.color(for: deliverable.urgency) }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 5) {
                Text(deliverable.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .strikethrough(deliverable.isDone, color: .secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if showProject {
                        Text(deliverable.project)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    if let notes = deliverable.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                UrgencyChip(text: deliverable.dueDisplay, color: color)
                Text(String(deliverable.due.prefix(10)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .glassCard(padding: 14)
        .contextMenu {
            if !deliverable.isDone {
                Button {
                    Task { _ = await store.markDeliverableDone(deliverable) }
                } label: {
                    Label("Mark done", systemImage: "checkmark.circle.fill")
                }
                Button {
                    Task { _ = await store.setDeliverableStatus(deliverable, status: "at_risk") }
                } label: {
                    Label("Flag at risk", systemImage: "exclamationmark.triangle")
                }
                Button {
                    Task { _ = await store.setDeliverableStatus(deliverable, status: "blocked") }
                } label: {
                    Label("Mark blocked", systemImage: "hand.raised")
                }
            }
            Button(role: .destructive) {
                Task { _ = await store.setDeliverableStatus(deliverable, status: "dropped") }
            } label: {
                Label("Drop", systemImage: "trash")
            }
        }
    }
}
