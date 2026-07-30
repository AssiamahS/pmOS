import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: PMStore

    private var onTrackFraction: Double {
        let open = store.allOpenDeliverables
        guard !open.isEmpty else { return 1 }
        let late = open.filter(\.isOverdue).count
        return Double(open.count - late) / Double(open.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard

                if let err = store.lastError {
                    ErrorBanner(message: err)
                }

                if !store.overdue.isEmpty {
                    section("Overdue", color: Theme.red) {
                        ForEach(store.overdue) { d in
                            DeliverableRow(deliverable: d)
                        }
                    }
                }

                if !store.dueSoon.isEmpty {
                    section("Landing this week", color: Theme.amber) {
                        ForEach(store.dueSoon) { d in
                            DeliverableRow(deliverable: d)
                        }
                    }
                }

                if store.overdue.isEmpty && store.dueSoon.isEmpty && store.lastError == nil {
                    emptyState
                }

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
        }
        .refreshable { await store.refresh() }
    }

    private var heroCard: some View {
        HStack(spacing: 20) {
            DeadlineRing(
                progress: onTrackFraction,
                label: "\(Int((onTrackFraction * 100).rounded()))%",
                sublabel: "on track"
            )
            .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: 10) {
                statLine(count: store.overdue.count, label: "overdue", color: Theme.red)
                statLine(count: store.dueSoon.count, label: "due in 7 days", color: Theme.amber)
                statLine(count: store.allOpenDeliverables.count, label: "open deliverables", color: Theme.accent)
            }
            Spacer(minLength: 0)
        }
        .glassCard(padding: 20)
    }

    private func statLine(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func section<Content: View>(_ title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .kerning(1.2)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.mint)
            Text("All clear")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Nothing overdue, nothing landing this week.\nTap + to commit to the next deliverable.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 28)
        .padding(.top, 24)
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(Theme.amber)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
    }
}
