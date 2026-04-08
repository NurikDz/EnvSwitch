import SwiftUI

@main
struct EnvSwitchApp: App {
    @StateObject private var manager = EnvironmentManager()
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        MenuBarExtra {
            VStack {
                Text("Switch Environment")
                    .font(.headline)
                    .padding(.top, 5)
                
                Divider()
                
                ForEach(manager.environments) { env in
                    Button(action: {
                        manager.toggleEnvironment(env)
                    }) {
                        HStack {
                            Image(systemName: env.iconName)
                            Text(env.name)
                            Spacer()
                            if manager.activeEnvId == env.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Settings...") {
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        } label: {
            // New Unique Prism/Switcher Icon
            ZStack {
                if let activeId = manager.activeEnvId,
                   let activeEnv = manager.environments.first(where: { $0.id == activeId }) {
                    // Morphing Icon based on active environment
                    Image(systemName: activeEnv.iconName)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                } else {
                    // Default Unique Icon (Custom Prism-like switch)
                    Image(systemName: "square.3.layers.3d")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                }
            }
        }
        
        Window("EnvSwitch Settings", id: "settings") {
            SettingsView(manager: manager)
                .frame(minWidth: 700, minHeight: 500)
                .background(.ultraThinMaterial)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
