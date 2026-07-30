import SwiftUI

@main
struct PMOSApp: App {
    @StateObject private var store = PMStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: PMStore
    @State private var tab: Tab = .today
    @State private var showNeedBy = false
    @State private var showSettings = false

    enum Tab: String, CaseIterable {
        case today = "Today"
        case projects = "Projects"
        case board = "Board"

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .projects: return "square.stack.3d.up.fill"
            case .board: return "checklist"
            }
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header
                content
            }

            floatingBar
        }
        .sheet(isPresented: $showNeedBy) { NeedBySheet() }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .task { await store.refresh() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.rawValue)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .today: TodayView()
        case .projects: ProjectsView()
        case .board: BoardView()
        }
    }

    private var floatingBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                ForEach(Tab.allCases, id: \.self) { t in
                    tabButton(t)
                }
                Button {
                    showNeedBy = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 44)
                        .background(Theme.accentGradient, in: Capsule())
                        .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 4)
                }
                .padding(.leading, 4)
            }
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1))
            .padding(.bottom, 12)
        }
    }

    private func tabButton(_ t: Tab) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35)) { tab = t }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: t.icon)
                    .font(.system(size: 15, weight: .semibold))
                if tab == t {
                    Text(t.rawValue)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(tab == t ? .white : Color.secondary)
            .padding(.horizontal, tab == t ? 16 : 12)
            .frame(height: 44)
            .background {
                if tab == t {
                    Capsule().fill(.white.opacity(0.12))
                }
            }
        }
    }
}
