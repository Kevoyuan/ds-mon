import SwiftUI

struct DeepSeekWhaleMark: View {
    var compact = false
    var animated = false

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                if !compact {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .whaleCyan.opacity(0.32),
                                    .whaleBlue.opacity(0.14),
                                    .clear
                                ],
                                center: .topLeading,
                                startRadius: size * 0.08,
                                endRadius: size * 0.72
                            )
                        )
                        .blur(radius: size * 0.03)
                }

                TailShape()
                    .fill(
                        LinearGradient(
                            colors: [.whaleCyan, .whaleBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.34, height: size * 0.32)
                    .rotationEffect(.degrees(-12))
                    .offset(x: size * 0.30, y: -size * 0.03)
                    .shadow(color: .whaleBlue.opacity(compact ? 0.14 : 0.28), radius: size * 0.08, x: 0, y: size * 0.03)

                WhaleBodyShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                .whaleMint,
                                .whaleCyan,
                                .whaleBlue,
                                .whaleInk
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        WhaleBodyShape()
                            .stroke(.white.opacity(0.38), lineWidth: max(1, size * 0.035))
                            .blur(radius: size * 0.005)
                    }
                    .overlay {
                        WhaleBodyShape()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.28), .clear, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: max(1, size * 0.025)
                            )
                            .blur(radius: size * 0.01)
                    }
                    .shadow(color: .whaleBlue.opacity(compact ? 0.18 : 0.34), radius: size * 0.10, x: 0, y: size * 0.05)

                if !compact {
                    WaveShape()
                        .stroke(.white.opacity(0.62), style: StrokeStyle(lineWidth: max(1, size * 0.025), lineCap: .round))
                        .frame(width: size * 0.48, height: size * 0.17)
                        .offset(x: -size * 0.02, y: size * 0.09)
                }

                Circle()
                    .fill(.white.opacity(0.95))
                    .frame(width: size * 0.075, height: size * 0.075)
                    .offset(x: -size * 0.18, y: -size * 0.08)

                Circle()
                    .fill(Color.whaleInk)
                    .frame(width: size * 0.038, height: size * 0.038)
                    .offset(x: -size * 0.17, y: -size * 0.075)

                if !compact {
                    waterSpout(size: size, x: -0.08, angle: -18, opacity: 0.72, height: 0.11)
                    waterSpout(size: size, x: 0.005, angle: 0, opacity: 0.59, height: 0.095)
                    waterSpout(size: size, x: 0.09, angle: 18, opacity: 0.46, height: 0.08)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .rotationEffect(animated ? .degrees(-1.8) : .zero)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animated)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func waterSpout(size: CGFloat, x: CGFloat, angle: Double, opacity: Double, height: CGFloat) -> some View {
        Capsule()
            .fill(Color.whaleCyan.opacity(opacity))
            .frame(width: size * 0.035, height: size * height)
            .rotationEffect(.degrees(angle))
            .offset(x: size * x, y: -size * 0.38)
    }
}

private struct WhaleBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.52))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.56, y: rect.minY + rect.height * 0.20),
            control1: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.25),
            control2: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.12)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.90, y: rect.minY + rect.height * 0.48),
            control1: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.28),
            control2: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.82),
            control1: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.78),
            control2: CGPoint(x: rect.minX + rect.width * 0.56, y: rect.minY + rect.height * 0.86)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.52),
            control1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.76),
            control2: CGPoint(x: rect.minX + rect.width * 0.13, y: rect.minY + rect.height * 0.66)
        )
        path.closeSubpath()
        return path
    }
}

private struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.08),
            control1: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.18),
            control2: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.83, y: rect.minY + rect.height * 0.33),
            control2: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.minY + rect.height * 0.43)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.92),
            control1: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.minY + rect.height * 0.56),
            control2: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.70)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.minY + rect.height),
            control2: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.82)
        )
        path.closeSubpath()
        return path
    }
}

private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY),
            control2: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY),
            control2: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.maxY)
        )
        return path
    }
}
