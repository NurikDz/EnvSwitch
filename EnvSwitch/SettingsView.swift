import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var manager: EnvironmentManager
    @State private var selectedEnvId: UUID?
    @State private var showingAppPicker = false

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack {
                Text("EnvSwitch")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top, 20)
                
                List(manager.environments, selection: $selectedEnvId) { env in
                    HStack {
                        Image(systemName: env.iconName)
                            .foregroundStyle(.blue)
                        Text(env.name)
                    }
                    .tag(env.id)
                }
                .listStyle(.sidebar)
                
                // Launch at Login Toggle
                VStack(spacing: 12) {
                    Toggle("Launch at Login", isOn: $manager.launchAtLogin)
                        .toggleStyle(.switch)
                        .font(.caption)
                    
                    Divider()
                    
                    VStack(spacing: 4) {
                        Text("Developer")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("NurikNoureddine")
                            .font(.caption.bold())
                        Link(destination: URL(string: "https://github.com/NurikDz")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                Text("GitHub")
                            }
                            .font(.caption2)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(width: 200)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Content
            VStack(alignment: .leading) {
                if let selectedEnvId = selectedEnvId,
                   let index = manager.environments.firstIndex(where: { $0.id == selectedEnvId }) {
                    
                    let env = Binding(
                        get: { manager.environments[index] },
                        set: { manager.environments[index] = $0 }
                    )
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            HStack {
                                Text(env.wrappedValue.name)
                                    .font(.system(size: 32, weight: .bold))
                                Spacer()
                                Button(action: { showingAppPicker.toggle() }) {
                                    Label("Add App", systemImage: "plus")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            // 1. App List Section
                            VStack(alignment: .leading) {
                                Text("Apps to Launch")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                if env.wrappedValue.appPaths.isEmpty {
                                    Text("No apps added yet.")
                                        .font(.caption)
                                        .padding()
                                } else {
                                    ForEach(env.wrappedValue.appPaths, id: \.self) { path in
                                        HStack {
                                            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                            Text(path.split(separator: "/").last?.replacingOccurrences(of: ".app", with: "") ?? "")
                                            Spacer()
                                            Button(action: { manager.removeApp(from: selectedEnvId, path: path) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // 2. Vibes Section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("System Vibes")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Toggle("Hide Other Apps (Focus Mode)", isOn: env.shouldHideOthers)
                                    .onChange(of: env.wrappedValue.shouldHideOthers) {
                                        manager.updateVibe(envId: selectedEnvId, darkMode: env.wrappedValue.isDarkMode, hideOthers: env.wrappedValue.shouldHideOthers, wallpaper: env.wrappedValue.wallpaperPath)
                                    }
                                
                                HStack {
                                    Text("Appearance:")
                                    Picker("", selection: env.isDarkMode) {
                                        Text("No Change").tag(nil as Bool?)
                                        Text("Light Mode").tag(false as Bool?)
                                        Text("Dark Mode").tag(true as Bool?)
                                    }
                                    .frame(width: 150)
                                    .onChange(of: env.wrappedValue.isDarkMode) {
                                        manager.updateVibe(envId: selectedEnvId, darkMode: env.wrappedValue.isDarkMode, hideOthers: env.wrappedValue.shouldHideOthers, wallpaper: env.wrappedValue.wallpaperPath)
                                    }
                                }
                                
                                HStack {
                                    Text("Wallpaper:")
                                    Text(env.wrappedValue.wallpaperPath?.split(separator: "/").last ?? "Default")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Button("Choose...") {
                                        pickWallpaper(envId: selectedEnvId)
                                    }
                                }
                            }
                        }
                        .padding(30)
                    }
                } else {
                    Text("Select an environment to customize.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(manager: manager, selectedEnvId: selectedEnvId!)
        }
        .onAppear {
            selectedEnvId = manager.environments.first?.id
        }
    }
    
    private func pickWallpaper(envId: UUID) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url {
            if let index = manager.environments.firstIndex(where: { $0.id == envId }) {
                manager.updateVibe(envId: envId, darkMode: manager.environments[index].isDarkMode, hideOthers: manager.environments[index].shouldHideOthers, wallpaper: url.path)
            }
        }
    }
}

struct AppPickerView: View {
    @ObservedObject var manager: EnvironmentManager
    let selectedEnvId: UUID
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss

    var filteredApps: [EnvironmentManager.AppInfo] {
        if searchText.isEmpty { return manager.installedApps }
        else { return manager.installedApps.filter { $0.name.lowercased().contains(searchText.lowercased()) } }
    }

    let columns = [GridItem(.adaptive(minimum: 70))]

    var body: some View {
        VStack {
            HStack {
                Text("Add Apps")
                    .font(.headline)
                Spacer()
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                Button("Done") { dismiss() }
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(filteredApps) { app in
                        Button(action: { manager.addApp(to: selectedEnvId, path: app.path) }) {
                            VStack {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                Text(app.name)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 400, height: 450)
        .background(.ultraThinMaterial)
    }
}
