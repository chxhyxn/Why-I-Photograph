import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal

enum ArtStyle: String, CaseIterable, Identifiable {
    case none = "Original"
    case grain = "Grain"
    case sepia = "Sepia"
    case noir = "Noir"
    case chrome = "Chrome"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none:     return "photo"
        case .grain:    return "film"
        case .sepia:    return "camera.filters"
        case .noir:     return "moon.fill"
        case .chrome:   return "sparkles"
        }
    }
}

class ImageProcessor: ObservableObject {
    private let ciContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    private let sourceCIImage: CIImage?
    private let previewCIImage: CIImage?
    let originalUIImage: UIImage

    private static let maxPreviewDimension: CGFloat = 1200

    private let exposureFilter = CIFilter.exposureAdjust()
    private let colorControlsFilter = CIFilter.colorControls()
    private let vignetteFilter = CIFilter.vignette()

    @Published var cropLeft: Double = 0
    @Published var cropRight: Double = 0
    @Published var cropTop: Double = 0
    @Published var cropBottom: Double = 0
    @Published var blurRadius: Double = 0
    @Published var brightness: Double = 0
    @Published var contrast: Double = 1
    @Published var saturation: Double = 1
    @Published var vignetteIntensity: Double = 0
    @Published var artStyle: ArtStyle = .none

    init() {
        let img = UIImage(named: "Bigsur")
            ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "Bigsur", ofType: "jpeg") ?? "")
            ?? UIImage()
        self.originalUIImage = img
        let source = CIImage(image: img)
        self.sourceCIImage = source

        if let ci = source {
            let maxDim = max(ci.extent.width, ci.extent.height)
            if maxDim > Self.maxPreviewDimension {
                let scale = Self.maxPreviewDimension / maxDim
                self.previewCIImage = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            } else {
                self.previewCIImage = ci
            }
        } else {
            self.previewCIImage = nil
        }
    }

    var processedImage: UIImage {
        guard var ci = previewCIImage else { return originalUIImage }

        ci = applyCrop(to: ci)

        if blurRadius > 0 {
            let blurred = ci.applyingGaussianBlur(sigma: blurRadius * 6).cropped(to: ci.extent)
            let center = CGPoint(x: ci.extent.midX, y: ci.extent.midY)
            let r = min(ci.extent.width, ci.extent.height) * 0.35
            let grad = CIFilter.radialGradient()
            grad.center = center
            grad.radius0 = Float(r * 0.5)
            grad.radius1 = Float(r)
            grad.color0 = CIColor.white
            grad.color1 = CIColor.black
            if let mask = grad.outputImage?.cropped(to: ci.extent) {
                let blend = CIFilter.blendWithMask()
                blend.inputImage = ci
                blend.backgroundImage = blurred
                blend.maskImage = mask
                if let out = blend.outputImage { ci = out }
            }
        }

        if abs(brightness) > 0.001 {
            exposureFilter.inputImage = ci
            exposureFilter.ev = Float(brightness)
            if let out = exposureFilter.outputImage { ci = out }
        }

        colorControlsFilter.inputImage = ci
        colorControlsFilter.brightness = 0
        colorControlsFilter.contrast = Float(contrast)
        colorControlsFilter.saturation = Float(saturation)
        if let out = colorControlsFilter.outputImage { ci = out }

        if vignetteIntensity > 0 {
            vignetteFilter.inputImage = ci
            vignetteFilter.intensity = Float(vignetteIntensity * 0.8)
            vignetteFilter.radius = Float(max(ci.extent.width, ci.extent.height) / 2)
            if let out = vignetteFilter.outputImage { ci = out }
        }

        ci = applyArt(to: ci)

        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return originalUIImage }
        return UIImage(cgImage: cg)
    }

    var originalForComparison: UIImage {
        guard var ci = previewCIImage else { return originalUIImage }
        ci = applyCrop(to: ci)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return originalUIImage }
        return UIImage(cgImage: cg)
    }

    private func applyCrop(to ci: CIImage) -> CIImage {
        let fullW = ci.extent.width
        let fullH = ci.extent.height
        let cX = fullW * CGFloat(cropLeft)
        let cY = fullH * CGFloat(cropTop)
        let cW = fullW * CGFloat(1 - cropLeft - cropRight)
        let cH = fullH * CGFloat(1 - cropTop - cropBottom)
        let cropRect = CGRect(x: cX, y: cY, width: cW, height: cH)
        guard cropRect.width > 0 && cropRect.height > 0 else { return ci }
        let cropped = ci.cropped(to: cropRect)
        return cropped.transformed(by: CGAffineTransform(translationX: -cropped.extent.origin.x,
                                                          y: -cropped.extent.origin.y))
    }

    private func applyArt(to image: CIImage) -> CIImage {
        switch artStyle {
        case .none:
            return image
        case .grain:
            let noise = CIFilter.randomGenerator()
            guard let noiseOut = noise.outputImage else { return image }
            let cropped = noiseOut.cropped(to: image.extent)
            let v = CIVector(x: 0, y: 1, z: 0, w: 0)
            let grain = cropped.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": v, "inputGVector": v, "inputBVector": v,
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.04)
            ])
            return grain.applyingFilter("CISourceOverCompositing",
                parameters: [kCIInputBackgroundImageKey: image]).cropped(to: image.extent)
        case .sepia:
            let s = CIFilter.sepiaTone()
            s.inputImage = image
            s.intensity = 0.4
            return s.outputImage ?? image
        case .noir:
            return image.applyingFilter("CIPhotoEffectNoir")
        case .chrome:
            return image.applyingFilter("CIPhotoEffectChrome")
        }
    }

    func reset() {
        cropLeft = 0; cropRight = 0; cropTop = 0; cropBottom = 0
        blurRadius = 0; brightness = 0
        contrast = 1; saturation = 1
        vignetteIntensity = 0; artStyle = .none
    }
}
