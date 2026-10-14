import AppKit
import Foundation

// Global references to prevent ARC deallocation in top-level script scope
var globalAppDelegate: AppDelegate?

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let monitor = AntigravityMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set as background accessory app (Menu bar item only)
        NSApp.setActivationPolicy(.accessory)
        
        print("[AntigravityRetry] App finished launching. Creating Status Bar item...")
        statusBarController = StatusBarController(monitor: monitor)
        
        NSApp.activate(ignoringOtherApps: true)
    }
}

let args = CommandLine.arguments

if args.contains("--help") || args.contains("-h") {
    print("""
    Antigravity Auto-Retry (macOS Native Menu Bar & CLI Tool)
    
    Usage:
      antigravity-retry [options]
    
    Options:
      --cli                 Run in continuous CLI background loop without menu bar icon
      --interval <seconds>  Set scan and retry interval in seconds (default: 1.0)
      --test-scan           Run a single scan on Antigravity windows
      --help, -h            Show this help menu
    """)
    exit(0)
}

if args.contains("--test-scan") {
    print("[AntigravityRetry] Running single test scan on Antigravity...")
    let monitor = AntigravityMonitor()
    monitor.performScan()
    Thread.sleep(forTimeInterval: 2.0)
    print("[AntigravityRetry] Test scan completed.")
    exit(0)
}

if args.contains("--cli") {
    if let idx = args.firstIndex(of: "--interval"), idx + 1 < args.count, let val = Double(args[idx + 1]) {
        ConfigManager.shared.config.retryIntervalSeconds = val
    }
    print("[AntigravityRetry] Running in CLI mode with interval \(ConfigManager.shared.config.retryIntervalSeconds)s...")
    let monitor = AntigravityMonitor()
    monitor.start()
    RunLoop.main.run()
} else {
    let app = NSApplication.shared
    globalAppDelegate = AppDelegate()
    app.delegate = globalAppDelegate
    app.run()
}
