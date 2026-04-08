import SwiftUI
import AppKit
import ServiceManagement

struct AppEnvironment: Identifiable, Codable {
    var id = UUID()
    var name: String
    var iconName: String
    var appPaths: [String] = []
    
    // Vibe Settings
    var isDarkMode: Bool? = nil
    var shouldHideOthers: Bool = false
    var wallpaperPath: String? = nil
}

class EnvironmentManager: ObservableObject {
    @Published var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    
    private let appService = SMAppService.mainApp
    
    @Published var environments: [AppEnvironment] = [
        AppEnvironment(name: "Coding", iconName: "terminal.fill"),
        AppEnvironment(name: "Gaming", iconName: "gamecontroller.fill"),
        AppEnvironment(name: "Binge", iconName: "play.tv.fill"),
        AppEnvironment(name: "Relax", iconName: "leaf.fill"),
        AppEnvironment(name: "Custom", iconName: "sparkles")
    ]
    
    @Published var activeEnvId: UUID? = nil
    @Published var installedApps: [AppInfo] = []

    struct AppInfo: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let path: String
        let icon: NSImage
    }

    private let saveKey = "SavedEnvironments_v3"
    
    init() {
        load()
        scanInstalledApps()
        self.launchAtLogin = appService.status == .enabled
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                if appService.status != .enabled {
                    try appService.register()
                }
            } else {
                if appService.status == .enabled {
                    try appService.unregister()
                }
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }

    func scanInstalledApps() {
        let fileManager = FileManager.default
        let appFolder = "/Applications"
        guard let urls = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: appFolder), includingPropertiesForKeys: nil) else { return }
        
        var apps: [AppInfo] = []
        for url in urls where url.pathExtension == "app" {
            let name = url.deletingPathExtension().lastPathComponent
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            apps.append(AppInfo(name: name, path: url.path, icon: icon))
        }
        self.installedApps = apps.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }
    
    func toggleEnvironment(_ environment: AppEnvironment) {
        activeEnvId = environment.id
        
        // 1. Launch Apps first
        for path in environment.appPaths {
            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.open(url)
        }
        
        // 2. Hide Others if requested
        if environment.shouldHideOthers {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSWorkspace.shared.hideOtherApplications()
            }
        }
        
        // 3. Apply System Vibes
        applySystemVibes(env: environment)
    }
    
    private func applySystemVibes(env: AppEnvironment) {
        // Dark Mode
        if let darkMode = env.isDarkMode {
            let script = "tell application \"System Events\" to tell appearance preferences to set dark mode to \(darkMode)"
            runAppleScript(script)
        }
        
        // Wallpaper
        if let wallpaper = env.wallpaperPath {
            let script = """
            tell application "System Events"
                set desktopCount to count of desktops
                repeat with i from 1 to desktopCount
                    set picture of desktop i to POSIX file "\(wallpaper)"
                end repeat
            end tell
            """
            runAppleScript(script)
        }
    }
    
    private func runAppleScript(_ script: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let error = String(data: data, encoding: .utf8) {
                    print("AppleScript error: \(error)")
                }
            }
        } catch {
            print("Failed to run AppleScript: \(error)")
        }
    }
    
    func addApp(to envId: UUID, path: String) {
        if let index = environments.firstIndex(where: { $0.id == envId }) {
            if !environments[index].appPaths.contains(path) {
                environments[index].appPaths.append(path)
                save()
            }
        }
    }
    
    func removeApp(from envId: UUID, path: String) {
        if let index = environments.firstIndex(where: { $0.id == envId }) {
            environments[index].appPaths.removeAll(where: { $0 == path })
            save()
        }
    }
    
    func updateVibe(envId: UUID, darkMode: Bool?, hideOthers: Bool, wallpaper: String?) {
        if let index = environments.firstIndex(where: { $0.id == envId }) {
            environments[index].isDarkMode = darkMode
            environments[index].shouldHideOthers = hideOthers
            environments[index].wallpaperPath = wallpaper
            save()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(environments) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([AppEnvironment].self, from: data) {
            environments = decoded
        }
    }
}
