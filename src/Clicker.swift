import Foundation
import ApplicationServices
import CoreGraphics
import AppKit

public class Clicker {
    
    /// Clicks a target AXUIElement directly via macOS Accessibility API (AXPress).
    /// DOES NOT move the physical mouse cursor at all.
    public static func pressAXElement(_ element: AXUIElement) -> Bool {
        let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
        return result == .success
    }
    
    /// NO-OP for mouse warping to prevent ANY mouse cursor disruption to user.
    public static func clickAtPoint(_ point: CGPoint) {
        // Deliberately DO NOT warp physical mouse cursor to avoid hijacking user's mouse!
        print("[Clicker] Safety mode: Skipping physical mouse warp to protect user's cursor.")
    }
}
