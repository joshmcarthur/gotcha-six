import SwiftUI

/// Flat teaching drawings (single accent). Replace Welcome / How-to C with unDraw assets later if desired.
struct WelcomeIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color("AccentColor").opacity(0.12))
                    .frame(width: w * 0.7, height: h * 0.55)
                    .offset(y: -h * 0.05)
                // Runner
                Capsule()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 28, height: 70)
                    .offset(x: -w * 0.08, y: -20)
                Circle()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 22, height: 22)
                    .offset(x: -w * 0.08, y: -62)
                // Rear cone
                Path { path in
                    path.move(to: CGPoint(x: w * 0.42, y: h * 0.42))
                    path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.22))
                    path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.72))
                    path.closeSubpath()
                }
                .fill(Color("AccentColor").opacity(0.35))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel("Runner with awareness behind them")
    }
}

struct HowToAIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Person
                Capsule()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 26, height: 64)
                    .position(x: w * 0.35, y: h * 0.55)
                Circle()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 20, height: 20)
                    .position(x: w * 0.35, y: h * 0.32)
                // Radar pack
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("AccentColor"))
                    .frame(width: 18, height: 14)
                    .position(x: w * 0.35 + 16, y: h * 0.48)
                // Cone behind
                Path { path in
                    path.move(to: CGPoint(x: w * 0.42, y: h * 0.48))
                    path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.28))
                    path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.72))
                    path.closeSubpath()
                }
                .fill(Color("AccentColor").opacity(0.3))
            }
        }
        .accessibilityLabel("Person with rear radar cone")
    }
}

struct HowToCIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.primary.opacity(0.35), lineWidth: 3)
                    .frame(width: w * 0.28, height: h * 0.55)
                    .position(x: w * 0.35, y: h * 0.5)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("AccentColor").opacity(0.25))
                    .frame(width: w * 0.38, height: h * 0.22)
                    .position(x: w * 0.68, y: h * 0.42)
                Text("Live")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                    .position(x: w * 0.68, y: h * 0.42)
            }
        }
        .accessibilityLabel("Phone away with Live Activity glance")
    }
}

struct CalibrationIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Wall
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 16, height: h * 0.7)
                    .position(x: w * 0.82, y: h * 0.5)
                // Person stepping back
                Capsule()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 24, height: 58)
                    .position(x: w * 0.4, y: h * 0.55)
                Circle()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: 18, height: 18)
                    .position(x: w * 0.4, y: h * 0.34)
                // Arrow toward wall
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.55))
                    path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.55))
                }
                .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color("AccentColor"))
                    .position(x: w * 0.7, y: h * 0.55)
            }
        }
        .accessibilityLabel("Step backward toward a wall")
    }
}
