import SwiftUI

struct ColorPhaseView: View {
    @ObservedObject var processor: ImageProcessor
    let onNext: () -> Void

    @State private var copyOpacity: Double = 0
    @State private var showControls = false
    @State private var showNext = false
    @State private var hasInteracted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // 대표문구
            Text("I can paint the scene with how it truly felt.")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(copyOpacity)
                .padding(.top, 48)
                .padding(.bottom, 24)
                .accessibilityAddTraits(.isHeader)

            // 사진 | 조작
            HStack(spacing: 0) {
                Image(uiImage: processor.processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(4)
                    .padding(.leading, 24)
                    .animation(.easeOut(duration: 0.1), value: processor.brightness)
                    .accessibilityIgnoresInvertColors(true)
                    .accessibilityLabel("Photograph with color adjustments applied")
                    .accessibilityValue(colorAccessibilityValue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showControls {
                    VStack(spacing: 16) {
                        sliderSection(icon: "sun.max", label: "Brightness",
                                      hint: "Adjusts the overall lightness of the image.",
                                      value: $processor.brightness, range: -0.5...0.5)
                        sliderSection(icon: "circle.righthalf.filled", label: "Contrast",
                                      hint: "Emphasizes the difference between highlights and shadows.",
                                      value: $processor.contrast, range: 0.8...1.2)
                        sliderSection(icon: "paintpalette", label: "Saturation",
                                      hint: "Controls color intensity. Pull to zero for black and white.",
                                      value: $processor.saturation, range: 0.5...1.5)
                        sliderSection(icon: "circle.dashed", label: "Vignette",
                                      hint: "Darkens the edges to naturally draw focus to the subject.",
                                      value: $processor.vignetteIntensity, range: 0...1)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 340)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxHeight: .infinity)

            // 넥스트버튼
            NextButton(label: "But that's not all.") { onNext() }
                .opacity(showNext && hasInteracted ? 1 : 0)
                .allowsHitTesting(showNext && hasInteracted)
                .padding(.top, 24)
                .padding(.bottom, 48)
        }
        .onAppear {
            if reduceMotion {
                copyOpacity = 1
                showControls = true
                showNext = true
            } else {
                withAnimation(.easeIn(duration: 0.8)) { copyOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showControls = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        guard !hasInteracted else { return }
                        withAnimation(.easeInOut(duration: 0.7)) { processor.brightness = 0.25 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                            if !hasInteracted { withAnimation(.easeInOut(duration: 0.7)) { processor.brightness = 0 } }
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showNext = true } }
            }
        }
    }

    @ViewBuilder
    private func sliderSection(icon: String, label: String, hint: String,
                               value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.55))
                Text(label)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
            }
            Text(hint)
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundColor(.white.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)
            Slider(value: value, in: range)
                .tint(.white.opacity(0.55))
                .onChange(of: value.wrappedValue) { hasInteracted = true }
        }
        .padding(.bottom, 4)
    }

    private var colorAccessibilityValue: String {
        var parts: [String] = []
        if abs(processor.brightness) > 0.01 {
            parts.append("brightness \(processor.brightness > 0 ? "increased" : "decreased")")
        }
        if abs(processor.contrast - 1) > 0.01 {
            parts.append("contrast \(processor.contrast > 1 ? "increased" : "decreased")")
        }
        if abs(processor.saturation - 1) > 0.01 {
            parts.append("saturation \(processor.saturation > 1 ? "increased" : "decreased")")
        }
        if processor.vignetteIntensity > 0.01 { parts.append("vignette applied") }
        return parts.isEmpty ? "No adjustments" : parts.joined(separator: ", ")
    }
}
