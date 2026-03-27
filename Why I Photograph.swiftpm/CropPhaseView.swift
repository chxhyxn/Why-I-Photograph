import SwiftUI

struct CropPhaseView: View {
    @ObservedObject var processor: ImageProcessor
    let onNext: () -> Void

    @State private var copyOpacity: Double = 0
    @State private var showControls = false
    @State private var showNext = false
    @State private var hasInteracted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cropStep: Double = 0.05

    var body: some View {
        VStack(spacing: 20) {
            Text("I choose what to remember, and what to let go.")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(copyOpacity)
                .padding(.top, 48)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if showControls {
                Image(uiImage: processor.originalUIImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        CropOverlay(
                            cropLeft: $processor.cropLeft,
                            cropRight: $processor.cropRight,
                            cropTop: $processor.cropTop,
                            cropBottom: $processor.cropBottom,
                            onInteract: { hasInteracted = true }
                        )
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                    .accessibilityIgnoresInvertColors(true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Photograph with adjustable crop overlay")
                    .accessibilityValue(cropAccessibilityValue)
                    .accessibilityHint("Use actions to adjust the crop from each side")
                    .accessibilityAction(named: "Crop more from left") {
                        withAnimation { processor.cropLeft = min(0.4, processor.cropLeft + cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop less from left") {
                        withAnimation { processor.cropLeft = max(0, processor.cropLeft - cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop more from right") {
                        withAnimation { processor.cropRight = min(0.4, processor.cropRight + cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop less from right") {
                        withAnimation { processor.cropRight = max(0, processor.cropRight - cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop more from top") {
                        withAnimation { processor.cropTop = min(0.4, processor.cropTop + cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop less from top") {
                        withAnimation { processor.cropTop = max(0, processor.cropTop - cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop more from bottom") {
                        withAnimation { processor.cropBottom = min(0.4, processor.cropBottom + cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Crop less from bottom") {
                        withAnimation { processor.cropBottom = max(0, processor.cropBottom - cropStep) }
                        hasInteracted = true
                    }
                    .accessibilityAction(named: "Reset crop") {
                        withAnimation {
                            processor.cropLeft = 0; processor.cropRight = 0
                            processor.cropTop = 0; processor.cropBottom = 0
                        }
                        hasInteracted = true
                    }
            }

            Spacer()

            NextButton(label: "But that's not all.") { onNext() }
                .opacity(showNext && hasInteracted ? 1 : 0)
                .allowsHitTesting(showNext && hasInteracted)
        }
        .padding(.bottom, 48)
        .onAppear {
            if reduceMotion {
                copyOpacity = 1
                showControls = true
                showNext = true
            } else {
                withAnimation(.easeIn(duration: 0.8)) { copyOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { showControls = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        guard !hasInteracted else { return }
                        withAnimation(.easeInOut(duration: 0.9)) {
                            processor.cropLeft = 0.09
                            processor.cropRight = 0.09
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !hasInteracted {
                                withAnimation(.easeInOut(duration: 0.9)) {
                                    processor.cropLeft = 0
                                    processor.cropRight = 0
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showNext = true } }
            }
        }
    }

    private var cropAccessibilityValue: String {
        let l = Int(processor.cropLeft * 100)
        let r = Int(processor.cropRight * 100)
        let t = Int(processor.cropTop * 100)
        let b = Int(processor.cropBottom * 100)
        if l == 0 && r == 0 && t == 0 && b == 0 { return "No crop applied" }
        var parts: [String] = []
        if l > 0 { parts.append("left \(l)%") }
        if r > 0 { parts.append("right \(r)%") }
        if t > 0 { parts.append("top \(t)%") }
        if b > 0 { parts.append("bottom \(b)%") }
        return "Cropped: \(parts.joined(separator: ", "))"
    }
}

// MARK: - Crop Overlay

struct CropOverlay: View {
    @Binding var cropLeft: Double
    @Binding var cropRight: Double
    @Binding var cropTop: Double
    @Binding var cropBottom: Double
    let onInteract: () -> Void

    var body: some View {
        GeometryReader { geo in
            let boxX = geo.size.width * CGFloat(cropLeft)
            let boxY = geo.size.height * CGFloat(cropTop)
            let boxW = geo.size.width * CGFloat(1 - cropLeft - cropRight)
            let boxH = geo.size.height * CGFloat(1 - cropTop - cropBottom)
            let cropBox = CGRect(x: boxX, y: boxY, width: boxW, height: boxH)

            ZStack {
                CropDimShape(cropBox: cropBox)
                    .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
                    .allowsHitTesting(false)

                Rectangle()
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                    .frame(width: boxW, height: boxH)
                    .position(x: cropBox.midX, y: cropBox.midY)
                    .allowsHitTesting(false)

                // 내부 드래그 → 박스 이동
                CropBoxPanArea(
                    cropLeft: $cropLeft, cropRight: $cropRight,
                    cropTop: $cropTop, cropBottom: $cropBottom,
                    geoSize: geo.size, onInteract: onInteract
                )

                // 코너 드래그 → 박스 크기 조절
                ForEach(0..<4, id: \.self) { corner in
                    DraggableCornerMark(
                        corner: corner,
                        cropLeft: $cropLeft, cropRight: $cropRight,
                        cropTop: $cropTop, cropBottom: $cropBottom,
                        geoSize: geo.size, onInteract: onInteract
                    )
                }
            }
        }
    }
}

// MARK: - Dim Shape

struct CropDimShape: Shape {
    let cropBox: CGRect
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        p.addRect(cropBox)
        return p
    }
}

// MARK: - Pan (박스 내부 드래그)

struct CropBoxPanArea: View {
    @Binding var cropLeft: Double
    @Binding var cropRight: Double
    @Binding var cropTop: Double
    @Binding var cropBottom: Double
    let geoSize: CGSize
    let onInteract: () -> Void

    @State private var startLeft: Double = 0
    @State private var startRight: Double = 0
    @State private var startTop: Double = 0
    @State private var startBottom: Double = 0
    @State private var dragging: Bool = false

    var boxX: CGFloat { geoSize.width * CGFloat(cropLeft) }
    var boxY: CGFloat { geoSize.height * CGFloat(cropTop) }
    var boxW: CGFloat { geoSize.width * CGFloat(1 - cropLeft - cropRight) }
    var boxH: CGFloat { geoSize.height * CGFloat(1 - cropTop - cropBottom) }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .frame(width: boxW, height: boxH)
            .position(x: boxX + boxW / 2, y: boxY + boxH / 2)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        if !dragging {
                            dragging = true
                            startLeft = cropLeft; startRight = cropRight
                            startTop = cropTop; startBottom = cropBottom
                        }
                        onInteract()
                        let dx = Double(value.translation.width / geoSize.width)
                        let dy = Double(value.translation.height / geoSize.height)
                        let clampedDX = max(-startLeft, min(startRight, dx))
                        let clampedDY = max(-startTop, min(startBottom, dy))
                        cropLeft   = startLeft   + clampedDX
                        cropRight  = startRight  - clampedDX
                        cropTop    = startTop    + clampedDY
                        cropBottom = startBottom - clampedDY
                    }
                    .onEnded { _ in dragging = false }
            )
    }
}

// MARK: - Draggable Corner

struct DraggableCornerMark: View {
    let corner: Int   // 0=TL 1=TR 2=BL 3=BR
    @Binding var cropLeft: Double
    @Binding var cropRight: Double
    @Binding var cropTop: Double
    @Binding var cropBottom: Double
    let geoSize: CGSize
    let onInteract: () -> Void

    @State private var startLeft: Double = 0
    @State private var startRight: Double = 0
    @State private var startTop: Double = 0
    @State private var startBottom: Double = 0
    @State private var dragging: Bool = false

    private let len: CGFloat = 28
    private let thick: CGFloat = 3
    private let hitPad: CGFloat = 24
    private let minBox: Double = 0.15   // 최소 박스 비율

    var pos: CGPoint {
        switch corner {
        case 0: return CGPoint(x: geoSize.width  * CGFloat(cropLeft),        y: geoSize.height * CGFloat(cropTop))
        case 1: return CGPoint(x: geoSize.width  * CGFloat(1 - cropRight),   y: geoSize.height * CGFloat(cropTop))
        case 2: return CGPoint(x: geoSize.width  * CGFloat(cropLeft),        y: geoSize.height * CGFloat(1 - cropBottom))
        default: return CGPoint(x: geoSize.width * CGFloat(1 - cropRight),   y: geoSize.height * CGFloat(1 - cropBottom))
        }
    }

    var hS: CGFloat { (corner == 0 || corner == 2) ? 1 : -1 }
    var vS: CGFloat { (corner == 0 || corner == 1) ? 1 : -1 }

    var body: some View {
        ZStack {
            Rectangle().fill(Color.white).frame(width: len, height: thick).offset(x: hS * len / 2)
            Rectangle().fill(Color.white).frame(width: thick, height: len).offset(y: vS * len / 2)
        }
        .frame(width: len + hitPad * 2, height: len + hitPad * 2)
        .contentShape(Rectangle())
        .position(pos)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !dragging {
                        dragging = true
                        startLeft = cropLeft; startRight = cropRight
                        startTop = cropTop; startBottom = cropBottom
                    }
                    onInteract()
                    let dx = Double(value.translation.width  / geoSize.width)
                    let dy = Double(value.translation.height / geoSize.height)
                    switch corner {
                    case 0: // TL
                        cropLeft = max(0, min(1 - startRight - minBox, startLeft + dx))
                        cropTop  = max(0, min(1 - startBottom - minBox, startTop + dy))
                    case 1: // TR
                        cropRight = max(0, min(1 - startLeft - minBox, startRight - dx))
                        cropTop   = max(0, min(1 - startBottom - minBox, startTop + dy))
                    case 2: // BL
                        cropLeft   = max(0, min(1 - startRight - minBox, startLeft + dx))
                        cropBottom = max(0, min(1 - startTop - minBox, startBottom - dy))
                    default: // BR
                        cropRight  = max(0, min(1 - startLeft - minBox, startRight - dx))
                        cropBottom = max(0, min(1 - startTop - minBox, startBottom - dy))
                    }
                }
                .onEnded { _ in dragging = false }
        )
    }
}
