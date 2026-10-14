import Foundation

public struct AppConfig: Codable {
    public var isEnabled: Bool
    public var retryIntervalSeconds: Double
    public var totalRetries: Int
    public var playSoundOnRetry: Bool
    public var targetApps: [String]
    
    public static var defaultConfig: AppConfig {
        return AppConfig(
            isEnabled: false, // Default to paused when starting app
            retryIntervalSeconds: 1.0,
            totalRetries: 0,
            playSoundOnRetry: false,
            targetApps: ["Antigravity", "Antigravity IDE"]
        )
    }
}

public class ConfigManager {
    public static let shared = ConfigManager()
    
    private let configFilePath: String
    public var config: AppConfig
    
    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        self.configFilePath = (homeDir as NSString).appendingPathComponent(".antigravity_retry_config.json")
        self.config = AppConfig.defaultConfig
        loadConfig()
    }
    
    public func loadConfig() {
        let url = URL(fileURLWithPath: configFilePath)
        guard FileManager.default.fileExists(atPath: configFilePath),
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            self.config = AppConfig.defaultConfig
            saveConfig()
            return
        }
        self.config = loaded
    }
    
    public func saveConfig() {
        let url = URL(fileURLWithPath: configFilePath)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self.config) {
            try? data.write(to: url)
        }
    }
    
    public func incrementRetryCount() {
        self.config.totalRetries += 1
        saveConfig()
    }
}
