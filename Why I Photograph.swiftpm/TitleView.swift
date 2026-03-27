import SwiftUI

struct TitleView: View {
    let onNext: () -> Void
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var pulse = false
    @State private var canAdvance = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Why I Love Photography")
                .font(.system(size: 42, weight: .light, design: .serif))
                .foregroundColor(.white)
                .opacity(titleOpacity)

            Text("Tap to begin")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(pulse ? 0.6 : 0.25))
                .opacity(subtitleOpacity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { guard canAdvance else { return }; haptic(.light); onNext() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Why I Love Photography")
        .accessibilityHint("Tap anywhere to begin the experience")
        .accessibilityAddTraits(.isButton)
        .accessibilityFocused($isFocused)
        .onAppear {
            if reduceMotion {
                titleOpacity = 1
                subtitleOpacity = 1
                canAdvance = true
            } else {
                withAnimation(.easeIn(duration: 1.5)) { titleOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.8)) { subtitleOpacity = 1 }
                    pulse = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        canAdvance = true
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
        }
    }
}
