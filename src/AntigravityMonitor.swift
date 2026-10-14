import Foundation
import ApplicationServices
import CoreGraphics
import AppKit

public protocol AntigravityMonitorDelegate: AnyObject {
    func monitorDidTriggerRetry(count: Int)
    func monitorDidUpdateStatus(message: String)
    func monitorNeedsAccessibilityPermission()
}

public class AntigravityMonitor {
    public weak var delegate: AntigravityMonitorDelegate?
    
    private var timer: Timer?
    private let queue = DispatchQueue(label: "com.antigravity.retry.axmonitor", qos: .userInitiated)
    private var isProcessing = false
    private var scanCount = 0
    
    public init() {}
    
    public func start() {
        stop()
        let interval = ConfigManager.shared.config.retryIntervalSeconds
        print("[AntigravityMonitor] 🚀 Started Native AX Button Monitor Loop (Interval: \(interval)s)")
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.performScan()
            }
        }
        delegate?.monitorDidUpdateStatus(message: "Active")
    }
    
    public func stop() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
        delegate?.monitorDidUpdateStatus(message: "Paused")
        print("[AntigravityMonitor] ⏸️ Stopped monitoring loop")
    }
    
    public func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    public func performScan() {
        guard ConfigManager.shared.config.isEnabled else { return }
        guard !isProcessing else { return }
        isProcessing = true
        scanCount += 1
        
        queue.async { [weak self] in
            defer { self?.isProcessing = false }
            self?.executeScanPipeline()
        }
    }
    
    private func executeScanPipeline() {
        let workspace = NSWorkspace.shared
        let targetAppNames = ConfigManager.shared.config.targetApps.map { $0.lowercased() }
        
        let runningApps = workspace.runningApplications.filter { app in
            guard let name = app.localizedName?.lowercased() else { return false }
            return targetAppNames.contains { name.contains($0) }
        }
        
        guard !runningApps.isEmpty else { return }
        
        for app in runningApps {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            
            // Force Enable Chromium/Electron Accessibility Tree
            var enabledFlag: CFTypeRef = true as CFTypeRef
            AXUIElementSetAttributeValue(appRef, "AXEnhancedUserInterface" as CFString, enabledFlag)
            AXUIElementSetAttributeValue(appRef, "AXManualAccessibility" as CFString, enabledFlag)
            
            var windowsRef: CFTypeRef?
            let res = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
            guard res == .success, let windows = windowsRef as? [AXUIElement] else { continue }
            
            for win in windows {
                var winPos = CGPoint.zero
                var winSize = CGSize.zero
                getAXFrame(element: win, position: &winPos, size: &winSize)
                
                guard winSize.width > 300 && winSize.height > 300 else { continue }
                
                // Strictly find the exact AXButton (excluding AXGroup card containers!)
                if let buttonElement = findAXRetryButton(in: win, windowOriginX: winPos.x, windowWidth: winSize.width) {
                    print("[AntigravityMonitor] 🎯 Found exact AXButton node in \(app.localizedName ?? "")! Triggering AXPress...")
                    
                    let pressRes = AXUIElementPerformAction(buttonElement, kAXPressAction as CFString)
                    if pressRes == .success {
                        print("[AntigravityMonitor] 🎉 AXPress action on AXButton returned SUCCESS!")
                        recordRetrySuccess()
                        return
                    } else {
                        print("[AntigravityMonitor] ⚠️ AXPress returned error code: \(pressRes.rawValue)")
                    }
                }
            }
        }
    }
    
    private func isRetryContainer(element: AXUIElement, depth: Int = 0) -> Bool {
        guard depth < 10 else { return false }
        
        var roleRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var valRef: CFTypeRef?
        var descRef: CFTypeRef?
        
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valRef)
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        
        let title = (titleRef as? String) ?? ""
        let val = (valRef as? String) ?? ""
        let desc = (descRef as? String) ?? ""
        
        let text = "\(title) \(val) \(desc)".lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if text == "retry" || text.contains("retry") {
            return true
        }
        
        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                if isRetryContainer(element: child, depth: depth + 1) {
                    return true
                }
            }
        }
        return false
    }
    
    /// Strict search for AXButton / AXLink nodes ONLY.
    private func findAXRetryButton(in element: AXUIElement, windowOriginX: CGFloat, windowWidth: CGFloat, depth: Int = 0) -> AXUIElement? {
        guard depth < 35 else { return nil }
        
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = (roleRef as? String) ?? ""
        
        // Strict role matching: AXButton or AXLink ONLY (Exclude AXGroup to avoid hitting outer card container)
        if role == "AXButton" || role == "AXLink" {
            if isRetryContainer(element: element) {
                if let pt = getElementCenterPoint(element: element) {
                    if pt.x >= windowOriginX + windowWidth * 0.35 {
                        return element
                    }
                } else {
                    return element
                }
            }
        }
        
        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findAXRetryButton(in: child, windowOriginX: windowOriginX, windowWidth: windowWidth, depth: depth + 1) {
                    return found
                }
            }
        }
        return nil
    }
    
    private func getAXFrame(element: AXUIElement, position: inout CGPoint, size: inout CGSize) {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
           AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success {
            _ = AXValueGetValue(posRef as! AXValue, .cgPoint, &position)
            _ = AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        }
    }
    
    private func getElementCenterPoint(element: AXUIElement) -> CGPoint? {
        var pos = CGPoint.zero
        var size = CGSize.zero
        getAXFrame(element: element, position: &pos, size: &size)
        guard size.width > 0 && size.height > 0 else { return nil }
        return CGPoint(x: pos.x + size.width / 2.0, y: pos.y + size.height / 2.0)
    }
    
    private func recordRetrySuccess() {
        ConfigManager.shared.incrementRetryCount()
        let total = ConfigManager.shared.config.totalRetries
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.monitorDidTriggerRetry(count: total)
        }
    }
}
