import SwiftUI

struct WholePictureView: View {
    @ObservedObject var processor: ImageProcessor
    let onNext: () -> Void

    @State private var sliderPos: CGFloat = 0.0
    @State private var quoteOpacity: Double = 0
    @State private var showNext = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { screen in
            VStack(spacing: 20) {
                Spacer(minLength: 0)

                ComparisonImage(
                    before: processor.originalForComparison,
                    after: processor.processedImage,
                    sliderPos: $sliderPos
                )
                .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    Text("This is what I love about photography.")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 1)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("\"To photograph is to put the head,\nthe eye, and the heart\non the same axis.\"")
                            .font(.system(size: 19, weight: .light, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Text("— Henri Cartier-Bresson")
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Quote by Henri Cartier-Bresson: To photograph is to put the head, the eye, and the heart on the same axis.")
                }
                .opacity(quoteOpacity)
                .padding(.horizontal, 32)

                Spacer(minLength: 0)

                if showNext {
                    NextButton(label: "Continue") { onNext() }
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 48)
            .frame(width: screen.size.width, height: screen.size.height)
        }
        .onAppear {
            if reduceMotion {
                sliderPos = 0.5
                quoteOpacity = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showNext = true }
            } else {
                sliderPos = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 2.5)) { sliderPos = 1.0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 1.0)) { sliderPos = 0.5 }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    withAnimation(.easeIn(duration: 1.2)) { quoteOpacity = 1 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                    withAnimation { showNext = true }
                }
            }
        }
    }
}

struct ComparisonImage: View {
    let before: UIImage
    let after: UIImage
    @Binding var sliderPos: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .leading) {
                Image(uiImage: after)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: w, height: h)
                    .clipped()

                Image(uiImage: before)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: w, height: h)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Color.white.frame(width: w * sliderPos)
                            Color.clear
                        }
                    )

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .offset(x: w * sliderPos - 1)

                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.black)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .position(x: w * sliderPos, y: h / 2)

                VStack {
                    HStack {
                        Text("BEFORE")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(5)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(3)
                        Spacer()
                        Text("AFTER")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(5)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(3)
                    }
                    .padding(10)
                    Spacer()
                }
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { val in
                sliderPos = max(0, min(1, val.location.x / w))
            })
        }
        .aspectRatio(imageAspect, contentMode: .fit)
        .cornerRadius(4)
        .accessibilityIgnoresInvertColors(true)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityLabel("Before and after comparison")
        .accessibilityValue("\(Int(sliderPos * 100)) percent showing edited version")
        .accessibilityHint("Drag left and right to compare original and edited photograph")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: sliderPos = min(1, sliderPos + 0.1)
            case .decrement: sliderPos = max(0, sliderPos - 0.1)
            @unknown default: break
            }
        }
    }

    private var imageAspect: CGFloat {
        let s = after.size
        guard s.height > 0 else { return 1.5 }
        return s.width / s.height
    }
}
