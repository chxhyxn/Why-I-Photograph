import SwiftUI

struct ClickView: View {
    @ObservedObject var processor: ImageProcessor
    let onNext: () -> Void

    @State private var copyOpacity: Double = 0
    @State private var showShutter = false
    @State private var shutterScale: CGFloat = 1.0
    @State private var showPhoto = false
    @State private var flashOpacity: Double = 0
    @State private var showNext = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var photoFocused: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()
                Text("All it takes is one click — and the moment is mine.")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(copyOpacity)
                    .accessibilityAddTraits(.isHeader)

                if showPhoto {
                    Image(uiImage: processor.originalUIImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(4)
                        .shadow(color: .white.opacity(0.1), radius: 20)
                        .padding(.horizontal, 24)
                        .accessibilityLabel("Captured photograph of Big Sur coastline with crashing waves and rocky cliffs")
                        .accessibilityIgnoresInvertColors(true)
                        .accessibilityFocused($photoFocused)
                }

                if !showPhoto && showShutter {
                    Button(action: shoot) {
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.8), lineWidth: 3)
                                .frame(width: 84, height: 84)
                            Circle().fill(Color.white)
                                .frame(width: 70, height: 70)
                        }
                        .scaleEffect(shutterScale)
                    }
                    .accessibilityLabel("Shutter button")
                    .accessibilityHint("Double-tap to take a photograph")
                    .transition(.opacity)
                }

                Spacer()

                if showNext {
                    NextButton(label: "But that's not all I love about it.") { onNext() }
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 48)

            Color.white.opacity(flashOpacity).ignoresSafeArea().allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onAppear {
            if reduceMotion {
                copyOpacity = 1
                showShutter = true
            } else {
                withAnimation(.easeIn(duration: 1.0)) { copyOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { showShutter = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) { shutterScale = 1.12 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.5)) { shutterScale = 1.0 }
                        }
                    }
                }
            }
        }
    }

    private func shoot() {
        haptic(.medium)
        if reduceMotion {
            showShutter = false
            showPhoto = true
            showNext = true
            UIAccessibility.post(notification: .announcement, argument: "Photo captured")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { photoFocused = true }
        } else {
            withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.9 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeIn(duration: 0.35)) { flashOpacity = 0 }
            }
            withAnimation(.easeOut(duration: 0.3)) { showShutter = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { showPhoto = true }
                UIAccessibility.post(notification: .announcement, argument: "Photo captured")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { photoFocused = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeIn(duration: 0.8)) { showNext = true }
                }
            }
        }
    }
}
