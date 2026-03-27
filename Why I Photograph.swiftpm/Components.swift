import SwiftUI

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

struct NextButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button { haptic(.light); action() } label: {
            Text(label)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
        }
        .accessibilityLabel(label)
        .accessibilityHint("Proceed to the next step")
    }
}