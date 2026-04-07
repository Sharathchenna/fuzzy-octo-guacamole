import SwiftUI

// MARK: - Settings View
struct ArcSettingsView: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(shellViewModel: shellViewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            AppearanceSettingsView(shellViewModel: shellViewModel)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(1)
            
            ProfileSettingsView(shellViewModel: shellViewModel)
                .tabItem {
                    Label("Profiles", systemImage: "person.2")
                }
                .tag(2)
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "shield")
                }
                .tag(3)
        }
        .padding(20)
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    
    var body: some View {
        Form {
            Section("Startup") {
                Picker("On startup", selection: .constant(0)) {
                    Text("Open new tab page").tag(0)
                    Text("Continue where you left off").tag(1)
                    Text("Open specific page").tag(2)
                }
                .pickerStyle(.radioGroup)
            }
            
            Section("Downloads") {
                HStack {
                    Text("Download location:")
                    Spacer()
                    Text("~/Downloads")
                        .foregroundStyle(.secondary)
                    Button("Change...") {}
                }
            }
            
            Section("Search") {
                Picker("Search engine", selection: .constant(0)) {
                    Text("Google").tag(0)
                    Text("Bing").tag(1)
                    Text("DuckDuckGo").tag(2)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    
    private var themeColors: ArcThemeColors {
        ArcThemeColors.themedColors(
            for: shellViewModel.selectedProfile.theme,
            appTheme: shellViewModel.selectedProfile.appTheme
        )
    }
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: Binding(
                    get: { shellViewModel.selectedProfile.appTheme },
                    set: { _ in
                        shellViewModel.toggleSelectedProfileAppTheme()
                    }
                )) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                HStack {
                    Text("Current theme preview:")
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.sidebarBackground)
                        .frame(width: 60, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.top, 8)
            }
            
            Section("Accent Color") {
                Picker("Accent", selection: Binding(
                    get: { shellViewModel.selectedProfile.theme },
                    set: { newTheme in
                        shellViewModel.updateSelectedProfileTheme(newTheme)
                    }
                )) {
                    ForEach(ProfileTheme.allCases, id: \.self) { theme in
                        HStack {
                            Circle()
                                .fill(theme.color)
                                .frame(width: 12, height: 12)
                            Text(theme.rawValue.capitalized)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            Section("Sidebar") {
                Toggle("Show favorites", isOn: .constant(true))
                Toggle("Show tab count badges", isOn: .constant(true))
                Toggle("Auto-collapse sidebar", isOn: .constant(false))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Profile Settings
struct ProfileSettingsView: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            List {
                ForEach(shellViewModel.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isSelected: profile.id == shellViewModel.selectedProfileID,
                        onSelect: {
                            shellViewModel.selectProfile(profile.id)
                        },
                        onRename: { newName in
                            shellViewModel.renameSelectedProfile(to: newName)
                        }
                    )
                }
            }
            
            HStack {
                Button {
                    // Add new profile
                } label: {
                    Label("Add Profile", systemImage: "plus")
                }
                
                Spacer()
                
                Button {
                    if shellViewModel.profiles.count > 1 {
                        shellViewModel.deleteSelectedProfile()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(shellViewModel.profiles.count <= 1)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Profile Row
struct ProfileRow: View {
    let profile: BrowserProfile
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: (String) -> Void
    
    @State private var isEditing = false
    @State private var editText = ""
    
    var body: some View {
        HStack {
            Circle()
                .fill(profile.theme.color)
                .frame(width: 12, height: 12)
            
            if isEditing {
                TextField("Profile name", text: $editText, onCommit: {
                    onRename(editText)
                    isEditing = false
                })
                .textFieldStyle(.roundedBorder)
            } else {
                Text(profile.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 10))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
        .contextMenu {
            Button {
                editText = profile.name
                isEditing = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
        }
    }
}

// MARK: - Privacy Settings
struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Block pop-up windows", isOn: .constant(true))
                Toggle("Prevent cross-site tracking", isOn: .constant(true))
                Toggle("Hide IP address", isOn: .constant(false))
            }
            
            Section("Data Management") {
                HStack {
                    Text("Clear browsing data")
                    Spacer()
                    Button("Clear Now...") {}
                }
                
                HStack {
                    Text("Manage cookies")
                    Spacer()
                    Button("Manage...") {}
                }
            }
            
            Section("Security") {
                Toggle("Warn when visiting fraudulent websites", isOn: .constant(true))
                Toggle("Enable secure DNS", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
    }
}
