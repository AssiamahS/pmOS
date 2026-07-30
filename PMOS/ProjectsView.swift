import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var store: PMStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.projects.isEmpty {
                    Text(store.lastError ?? "No projects yet — add a deliverable with +")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .glassCard(padding: 24)
                        .padding(.top, 24)
                }
                ForEach(store.projects) { project in
                    ProjectCard(project: project)
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
        }
        .refreshable { await store.refresh() }
    }
}

struct ProjectCard: View {
    let project: ProjectStatus
    @State private var expanded = true

    private var doneFraction: Double {
        guard !project.deliverables.isEmpty else { return 0 }
        return Double(project.doneDeliverables.count) / Double(project.deliverables.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(duration: 0.35)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.accentGradient)
                            .frame(width: 42, height: 42)
                            .opacity(0.85)
                        Text(String(project.key.prefix(2)).uppercased())
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.key)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if let repo = project.meta.repo {
                            Text(repo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(project.openDeliverables.count) open")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ProgressView(value: doneFraction)
                            .tint(Theme.mint)
                            .frame(width: 64)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
            }

            if expanded {
                if project.deliverables.isEmpty {
                    Text("No deliverables")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(project.openDeliverables) { d in
                            DeliverableRow(deliverable: d, showProject: false)
                        }
                    }
                    if !project.doneDeliverables.isEmpty {
                        Text("✓ \(project.doneDeliverables.map(\.title).joined(separator: " · "))")
                            .font(.caption)
                            .foregroundStyle(Theme.mint.opacity(0.8))
                            .lineLimit(2)
                    }
                }
            }
        }
        .glassCard(padding: 16)
    }
}
