import SwiftUI

struct PlaybackStatusBadge: View {
    let isPlaying: Bool
    let eventName: String
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPlaying ? .green : .secondary)
                .frame(width: 10, height: 10)
                .scaleEffect(isPlaying && pulse ? 1.45 : 1)
                .opacity(isPlaying && pulse ? 0.45 : 1)

            Text(isPlaying ? "PLAYING" : "STOPPED")
                .font(.caption.bold())

            if isPlaying, !eventName.isEmpty {
                Text(eventName)
                    .font(.caption.monospaced())
                    .lineLimit(1)
            }
        }
        .foregroundStyle(isPlaying ? Color.green : Color.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            (isPlaying ? Color.green : Color.secondary).opacity(0.12),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke((isPlaying ? Color.green : Color.secondary).opacity(0.35))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct EventTransformControl: View {
    @Binding var angleX: Double
    @Binding var offsetY: Double
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isCompact {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Direction").font(.headline)
                        Spacer()
                        resetButton
                    }
                    directionValue
                }
            } else {
                HStack {
                    Text("Direction").font(.headline)
                    Spacer()
                    directionValue
                    resetButton
                }
            }

            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.08))
                    Path { path in
                        path.move(to: CGPoint(x: size.width / 2, y: 0))
                        path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                        path.move(to: CGPoint(x: 0, y: size.height / 2))
                        path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                    }
                    .stroke(.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [5]))

                    Image(systemName: "figure.stand")
                        .font(.system(size: 54))
                        .foregroundStyle(.secondary.opacity(0.45))

                    Image(systemName: "location.north.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .rotationEffect(.degrees(angleX))
                        .position(
                            x: (angleX / 360 + 0.5) * size.width,
                            y: (0.5 - offsetY) * size.height
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { value in
                        let x = min(max(value.location.x / size.width, 0), 1)
                        let y = min(max(value.location.y / size.height, 0), 1)
                        angleX = (x - 0.5) * 360
                        offsetY = 0.5 - y
                    }
                )
            }
            .frame(height: 140)
        }
    }

    private var directionValue: some View {
        Text("Angle \(angleX, specifier: "%.0f")° · Y \(offsetY, specifier: "%.2f")")
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }

    private var resetButton: some View {
        Button("Reset") {
            angleX = 0
            offsetY = 0
        }
    }
}
