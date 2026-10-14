import Foundation
import Vision
import CoreGraphics
import AppKit

print("=== Testing Scan on Antigravity Window [X: 164, Y: 45, W: 1547, H: 989] ===")

let tempPath = "/tmp/antigravity_window_test.png"
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
task.arguments = ["-x", tempPath]

do {
    try task.run()
    task.waitUntilExit()
} catch {
    print("Screencapture error: \(error)")
    exit(1)
}

defer {
    try? FileManager.default.removeItem(atPath: tempPath)
}

guard let nsImage = NSImage(contentsOfFile: tempPath) else {
    print("Could not load image")
    exit(1)
}

var rect = CGRect(origin: .zero, size: nsImage.size)
guard let displayImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
    print("Could not get CGImage")
    exit(1)
}

let screenBounds = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
let displayWidth = CGFloat(displayImage.width)
let displayHeight = CGFloat(displayImage.height)
let scaleX = displayWidth / screenBounds.width
let scaleY = displayHeight / screenBounds.height

print("Screen bounds points:", screenBounds)
print("Display pixels:", displayWidth, "x", displayHeight)
print("Scale X:", scaleX, "Scale Y:", scaleY)

let windowBounds = CGRect(x: 164, y: 45, width: 1547, height: 989)
let cropRect = CGRect(
    x: windowBounds.origin.x * scaleX,
    y: windowBounds.origin.y * scaleY,
    width: windowBounds.width * scaleX,
    height: windowBounds.height * scaleY
)

guard let windowImage = displayImage.cropping(to: cropRect) else {
    print("Failed to crop image")
    exit(1)
}

let requestHandler = VNImageRequestHandler(cgImage: windowImage, options: [:])
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

try? requestHandler.perform([request])
guard let observations = request.results else {
    print("No OCR results")
    exit(0)
}

print("\n--- OCR Results inside Antigravity Window ---")
for obs in observations {
    guard let candidate = obs.topCandidates(1).first else { continue }
    let text = candidate.string
    let box = obs.boundingBox
    
    let clickXInWindow = box.midX * windowBounds.width
    let clickYInWindow = (1.0 - box.midY) * windowBounds.height
    let globalX = windowBounds.origin.x + clickXInWindow
    let globalY = windowBounds.origin.y + clickYInWindow
    
    if text.lowercased().contains("retry") || text.lowercased().contains("error") || text.lowercased().contains("dismiss") || text.lowercased().contains("traffic") {
        print("MATCH -> Text: '\(text)' | box.midX: \(String(format: "%.3f", box.midX)), midY: \(String(format: "%.3f", box.midY)) | Click Target: (\(Int(globalX)), \(Int(globalY)))")
    }
}
