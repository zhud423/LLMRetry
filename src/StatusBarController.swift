import AppKit
import Foundation

public class StatusBarController: NSObject, AntigravityMonitorDelegate {
    public let statusItem: NSStatusItem
    private var monitor: AntigravityMonitor
    
    private var toggleMenuItem: NSMenuItem!
    private var statsMenuItem: NSMenuItem!
    private var statusMenuItem: NSMenuItem!
    private var intervalMenu: NSMenu!
    
    public init(monitor: AntigravityMonitor) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.monitor = monitor
        super.init()
        
        // Force default to paused on launch
        ConfigManager.shared.config.isEnabled = false
        ConfigManager.shared.saveConfig()
        
        self.monitor.delegate = self
        
        setupMenu()
        updateStatusItemTitle()
        
        // Default paused: do not auto start
        self.monitor.stop()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Header Status
        statusMenuItem = NSMenuItem(title: "Status: Paused", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        statsMenuItem = NSMenuItem(title: "Total Retries: \(ConfigManager.shared.config.totalRetries)", action: nil, keyEquivalent: "")
        statsMenuItem.isEnabled = false
        menu.addItem(statsMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Toggle Active/Pause (Default paused)
        let isEnabled = ConfigManager.shared.config.isEnabled
        toggleMenuItem = NSMenuItem(
            title: isEnabled ? "Pause Auto-Retry" : "Resume Auto-Retry",
            action: #selector(toggleMonitoring),
            keyEquivalent: "t"
        )
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)
        
        // Submenu: Interval
        let intervalMenuItem = NSMenuItem(title: "Retry Interval", action: nil, keyEquivalent: "")
        intervalMenu = NSMenu()
        
        let intervals: [(String, Double)] = [
            ("⚡ 0.5s (Instant)", 0.5),
            ("⏱️ 1.0s (Default)", 1.0),
            ("🐢 2.0s", 2.0),
            ("🐌 5.0s", 5.0)
        ]
        
        let currentInterval = ConfigManager.shared.config.retryIntervalSeconds
        for (title, value) in intervals {
            let item = NSMenuItem(title: title, action: #selector(changeInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = (abs(currentInterval - value) < 0.1) ? .on : .off
            intervalMenu.addItem(item)
        }
        intervalMenuItem.submenu = intervalMenu
        menu.addItem(intervalMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Antigravity Retry", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func updateStatusItemTitle() {
        let isEnabled = ConfigManager.shared.config.isEnabled
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let button = self.statusItem.button else { return }
            
            let symbolName = isEnabled ? "arrow.clockwise.circle.fill" : "pause.circle.fill"
            if let sysImg = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Antigravity Retry") {
                sysImg.isTemplate = true
                button.image = sysImg
            }
            button.title = ""
            button.toolTip = isEnabled ? "Antigravity Retry: Active" : "Antigravity Retry: Paused"
        }
    }
    
    @objc private func toggleMonitoring() {
        ConfigManager.shared.config.isEnabled.toggle()
        ConfigManager.shared.saveConfig()
        
        let isEnabled = ConfigManager.shared.config.isEnabled
        toggleMenuItem.title = isEnabled ? "Pause Auto-Retry" : "Resume Auto-Retry"
        updateStatusItemTitle()
        
        if isEnabled {
            monitor.start()
        } else {
            monitor.stop()
        }
    }
    
    @objc private func changeInterval(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? Double else { return }
        ConfigManager.shared.config.retryIntervalSeconds = interval
        ConfigManager.shared.saveConfig()
        
        for item in intervalMenu.items {
            if let itemVal = item.representedObject as? Double {
                item.state = (abs(itemVal - interval) < 0.1) ? .on : .off
            }
        }
        
        if ConfigManager.shared.config.isEnabled {
            monitor.start()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - AntigravityMonitorDelegate
    public func monitorDidTriggerRetry(count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.statsMenuItem.title = "Total Retries: \(count)"
            self?.updateStatusItemTitle()
        }
        print("[StatusBarController] Pure AX Auto-Retry triggered successfully! Total count: \(count)")
    }
    
    public func monitorDidUpdateStatus(message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusMenuItem.title = "Status: \(message)"
        }
    }
    
    public func monitorNeedsAccessibilityPermission() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusItemTitle()
        }
    }
}
