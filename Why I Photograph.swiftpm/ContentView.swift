import SwiftUI

enum AppPhase: Int, CaseIterable {
    case title, click, crop, color, heart, wholePicture, outro

    var announcementText: String {
        switch self {
        case .title:        return "Why I Love Photography"
        case .click:        return "Capture: Tap the shutter to take a photo"
        case .crop:         return "Crop: Adjust the frame of your photo"
        case .color:        return "Color: Adjust brightness, contrast, and saturation"
        case .heart:        return "Style: Choose an artistic filter"
        case .wholePicture: return "Compare: See your photo before and after"
        case .outro:        return "What do you love about photography?"
        }
    }
}

struct ContentView: View {
    @StateObject private var processor = ImageProcessor()
    @State private var phase: AppPhase = .title
    @State private var transitioning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Group {
                switch phase {
                case .title:        TitleView { advance() }
                case .click:        ClickView(processor: processor) { advance() }
                case .crop:         CropPhaseView(processor: processor) { advance() }
                case .color:        ColorPhaseView(processor: processor) { advance() }
                case .heart:        HeartPhaseView(processor: processor) { advance() }
                case .wholePicture: WholePictureView(processor: processor) { advance() }
                case .outro:        OutroView {
                    processor.reset()
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.0)) { phase = .title }
                }
                }
            }
            .transition(.opacity)
        }
        .preferredColorScheme(.dark)
        .onChange(of: phase) {
            let text = phase.announcementText
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.1 : 0.5)) {
                UIAccessibility.post(notification: .screenChanged, argument: text)
            }
        }
    }

    private func advance() {
        guard !transitioning else { return }
        transitioning = true
        let all = AppPhase.allCases
        guard let idx = all.firstIndex(of: phase), idx + 1 < all.count else {
            transitioning = false; return
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) { phase = all[idx + 1] }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.1 : 0.9)) { transitioning = false }
    }
}
