import SwiftUI

/// The signature "Calm Focus" interaction: an empty ring that becomes a filled teal disc
/// with a checkmark that **draws** itself on. No bounce, no overshoot, no confetti — a
/// quiet exhale.
///
/// The component owns its animation: callers just flip `isComplete` (no `withAnimation`
/// needed). 44pt tap target with VoiceOver labels baked in.
public struct CompletionToggle: View {
    private let isComplete: Bool
    private let diameter: CGFloat
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(isComplete: Bool, diameter: CGFloat = 24, action: @escaping () -> Void) {
        self.isComplete = isComplete
        self.diameter = diameter
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                // Unchecked ring — fades out as the disc grows in (~0.3s).
                Circle()
                    .strokeBorder(Color.dsInk3, lineWidth: 1.7)
                    .opacity(isComplete ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isComplete)

                // Checked disc — scales 0.1 → 1 with a gentle ease-out (~0.4s), no overshoot.
                Circle()
                    .fill(Color.dsAccent)
                    .scaleEffect(isComplete ? 1 : 0.1)
                    .opacity(isComplete ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: isComplete)

                // Checkmark — strokes on via trim, slightly after the disc (~0.35s, 0.1s delay).
                CheckmarkShape()
                    .trim(from: 0, to: isComplete ? 1 : 0)
                    .stroke(Color.white,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .padding(diameter * 0.28)
                    .opacity(isComplete ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(isComplete ? 0.1 : 0), value: isComplete)
            }
            .frame(width: diameter, height: diameter)
            .frame(width: DSSpacing.minTapTarget, height: DSSpacing.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDimButtonStyle())
        .opacity(isEnabled ? 1 : 0.32)
        .accessibilityLabel(isComplete ? "Mark as not completed" : "Mark as completed")
        .accessibilityAddTraits(isComplete ? [.isSelected] : [])
    }
}

/// The checkmark path, sized to its rect so `trim` can animate the draw-on.
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.54))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.28))
        return path
    }
}

/// Shared press feedback: ~0.86 scale + slight dim. Calm, quick (~0.12s).
struct PressDimButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Completion toggle") {
    struct Demo: View {
        @State private var done = false
        var body: some View {
            CompletionToggle(isComplete: done) { done.toggle() }
                .padding()
        }
    }
    return Demo()
}
