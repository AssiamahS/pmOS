import SwiftUI

enum Theme {
    static let bgTop = Color(red: 0.043, green: 0.055, blue: 0.09)
    static let bgBottom = Color(red: 0.075, green: 0.106, blue: 0.173)
    static let accent = Color(red: 0.42, green: 0.55, blue: 1.0)
    static let violet = Color(red: 0.62, green: 0.44, blue: 1.0)
    static let mint = Color(red: 0.30, green: 0.87, blue: 0.65)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.30)
    static let red = Color(red: 1.0, green: 0.38, blue: 0.40)

    static let accentGradient = LinearGradient(
        colors: [accent, violet],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func color(for urgency: Urgency) -> Color {
        switch urgency {
        case .overdue: return red
        case .critical: return amber
        case .soon: return Color(red: 1.0, green: 0.88, blue: 0.42)
        case .calm: return accent
        case .done: return mint
        }
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(colors: [Theme.bgTop, Theme.bgBottom],
                       startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Theme.violet.opacity(0.16))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(x: 80, y: -120)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: -80, y: 100)
            }
            .ignoresSafeArea()
    }
}

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.14), .white.opacity(0.03)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

struct UrgencyChip: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
    }
}

struct DeadlineRing: View {
    /// 0...1 — fraction of deliverables that are on track
    let progress: Double
    let label: String
    let sublabel: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0.02, progress))
                .stroke(Theme.accentGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(sublabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
