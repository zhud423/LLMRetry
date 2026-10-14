import Foundation
import Vision
import CoreGraphics
import AppKit

print("=== Live OCR Diagnostic Test ===")

let tempPath = "/tmp/antigravity_live_test.png"
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
task.arguments = ["-x", tempPath]

do {
    try task.run()
    task.waitUntilExit()
} catch {
    print("Error executing screencapture: \(error)")
    exit(1)
}

defer {
    try? FileManager.default.removeItem(atPath: tempPath)
}

guard let nsImage = NSImage(contentsOfFile: tempPath) else {
    print("Failed to load screencapture image")
    exit(1)
}

var rect = CGRect(origin: .zero, size: nsImage.size)
guard let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
    print("Failed to get CGImage")
    exit(1)
}

let imageWidth = CGFloat(cgImage.width)
let imageHeight = CGFloat(cgImage.height)
print("Captured screen pixel dimensions:", imageWidth, "x", imageHeight)

let screenBounds = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
print("NSScreen main bounds in points:", screenBounds)

let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

try? requestHandler.perform([request])
guard let observations = request.results else {
    print("No observations returned")
    exit(0)
}

print("\n--- Recognized Text Observations containing 'retry' or 'error' or 'traffic' ---")
for obs in observations {
    guard let candidate = obs.topCandidates(1).first else { continue }
    let text = candidate.string
    let lower = text.lowercased()
    
    if lower.contains("retry") || lower.contains("error") || lower.contains("traffic") || lower.contains("dismiss") {
        let box = obs.boundingBox
        let clickX = box.midX * screenBounds.width
        let clickY = (1.0 - box.midY) * screenBounds.height
        
        print("Text: '\(text)' | midX: \(String(format: "%.3f", box.midX)), midY: \(String(format: "%.3f", box.midY)) | Screen Point: (\(Int(clickX)), \(Int(clickY)))")
    }
}
