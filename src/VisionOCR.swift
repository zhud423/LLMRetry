import Foundation
import Vision
import CoreGraphics

public class VisionOCR {
    
    /// Performs text recognition on a CGImage using macOS Vision framework
    public static func recognizeText(in image: CGImage) -> [VNRecognizedTextObservation] {
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        do {
            try requestHandler.perform([request])
            return request.results ?? []
        } catch {
            print("[VisionOCR] Error performing text recognition: \(error)")
            return []
        }
    }
    
    /// Pure Visual Blue Button Pixel Color Scanner
    /// Searches window pixel buffer directly for Antigravity's signature blue Retry button (R < 80, G: 80..180, B >= 180)
    public static func findBlueButtonPixelRect(image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        
        guard let pixelData = image.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return nil }
        
        let bytesPerPixel = image.bitsPerPixel / 8
        let bytesPerRow = image.bytesPerRow
        
        // Scan right 65% of window image (excluding left sidebar)
        let startX = Int(Double(width) * 0.35)
        
        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0
        var count = 0
        
        // Grid scan with step 2 for ultra-fast performance (< 2ms)
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: startX, to: width, by: 2) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = data[offset]
                let g = data[offset + 1]
                let b = data[offset + 2]
                
                // Signature Antigravity Blue Button Color (R < 80, G 80..180, B >= 180)
                if r < 90 && g >= 70 && g <= 190 && b >= 170 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                    count += 1
                }
            }
        }
        
        guard count > 30 else { return nil }
        
        let btnWidth = maxX - minX
        let btnHeight = maxY - minY
        
        // Valid blue button bounding box dimensions
        if btnWidth >= 25 && btnWidth <= 250 && btnHeight >= 15 && btnHeight <= 80 {
            print("[VisionOCR] Found Blue Retry Button visually! Bounding rect in image: (\(minX), \(minY), \(btnWidth)x\(btnHeight)), Pixel Count: \(count)")
            return CGRect(x: minX, y: minY, width: btnWidth, height: btnHeight)
        }
        
        return nil
    }
    
    /// Finds target Retry click point on screen using Visual Blue Button Color Matcher + Vision OCR
    public static func findRetryClickPoint(image: CGImage, windowBounds: CGRect) -> CGPoint? {
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        
        // Strategy A: Visual Blue Button Color Matching (Fastest & Most Reliable for UI buttons)
        if let blueRect = findBlueButtonPixelRect(image: image) {
            let midXPixel = blueRect.midX
            let midYPixel = blueRect.midY
            
            let clickXInWindow = (midXPixel / imageWidth) * windowBounds.width
            let clickYInWindow = (midYPixel / imageHeight) * windowBounds.height
            
            let globalPoint = CGPoint(
                x: windowBounds.origin.x + clickXInWindow,
                y: windowBounds.origin.y + clickYInWindow
            )
            print("[VisionOCR] Calculated global screen point from Visual Blue Button: \(globalPoint)")
            return globalPoint
        }
        
        // Strategy B: Vision OCR Text Recognition Fallback
        let observations = recognizeText(in: image)
        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            let text = candidate.string
            let lowerText = text.lowercased()
            let box = obs.boundingBox
            
            if box.midX >= 0.35 && (text == "Retry" || lowerText == "retry" || lowerText.contains("retry")) {
                let clickXInWindow = box.midX * windowBounds.width
                let clickYInWindow = (1.0 - box.midY) * windowBounds.height
                
                let globalPoint = CGPoint(
                    x: windowBounds.origin.x + clickXInWindow,
                    y: windowBounds.origin.y + clickYInWindow
                )
                print("[VisionOCR] Calculated global screen point from Vision OCR Text: \(globalPoint)")
                return globalPoint
            }
        }
        
        return nil
    }
}
