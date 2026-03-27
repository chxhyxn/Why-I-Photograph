import SwiftUI

struct HeartPhaseView: View {
    @ObservedObject var processor: ImageProcessor
    let onNext: () -> Void

    @State private var copyOpacity: Double = 0
    @State private var showNext = false
    @State private var hasInteracted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let styles: [ArtStyle] = [.grain, .sepia, .noir, .chrome]

    var body: some View {
        VStack(spacing: 0) {
            // 대표문구
            Text("I see the world my way — and make it my own.")
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
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: processor.artStyle.id)
                    .accessibilityIgnoresInvertColors(true)
                    .accessibilityLabel("Photograph with \(processor.artStyle.rawValue) style applied")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 10) {
                    ForEach(styles) { style in
                        ArtCard(style: style, isSelected: processor.artStyle == style) {
                            haptic(.light)
                            hasInteracted = true
                            withAnimation(.easeInOut(duration: 0.3)) {
                                processor.artStyle = processor.artStyle == style ? .none : style
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: 280)
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
                showNext = true
            } else {
                withAnimation(.easeIn(duration: 0.8)) { copyOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showNext = true } }
            }
        }
    }
}

struct ArtCard: View {
    let style: ArtStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: style.icon).font(.system(size: 20))
                Text(style.rawValue).font(.system(size: 15, weight: .medium, design: .serif))
                Spacer()
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.white : Color.white.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(isSelected ? 0 : 0.25), lineWidth: 1))
        }
        .accessibilityLabel("\(style.rawValue) style")
        .accessibilityHint(isSelected ? "Currently selected. Tap to remove" : "Tap to apply \(style.rawValue) effect")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
