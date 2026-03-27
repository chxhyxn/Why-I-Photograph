import SwiftUI

struct OutroView: View {
    let onRestart: () -> Void

    @State private var w1: Double = 0
    @State private var w2: Double = 0
    @State private var w3: Double = 0
    @State private var restartOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var questionFocused: Bool

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            HStack(spacing: 8) {
                Text("What do you love").opacity(w1)
                Text("about").opacity(w2)
                Text("photography?").opacity(w3)
            }
            .font(.system(size: 36, weight: .light, design: .serif))
            .foregroundColor(.white)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("What do you love about photography?")
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($questionFocused)
            Spacer()
            Button { haptic(.light); onRestart() } label: {
                Text("Start Over")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.35))
            }
            .accessibilityLabel("Start Over")
            .accessibilityHint("Returns to the beginning of the experience")
            .opacity(restartOpacity)
        }
        .padding(.bottom, 60)
        .onAppear {
            if reduceMotion {
                w1 = 1; w2 = 1; w3 = 1
                restartOpacity = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { questionFocused = true }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeIn(duration: 0.8)) { w1 = 1 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    withAnimation(.easeIn(duration: 0.8)) { w2 = 1 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                    withAnimation(.easeIn(duration: 1.0)) { w3 = 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { questionFocused = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                    withAnimation(.easeIn(duration: 1.5)) { restartOpacity = 1 }
                }
            }
        }
    }
}
