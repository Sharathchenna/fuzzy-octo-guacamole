//
//  ArcBrowserApp.swift
//  ArcBrowser
//
//  Created by Sharath Chenna on 04/04/26.
//

import SwiftUI
import AppKit
import Combine

// Global theme color storage for window background
@MainActor
class WindowThemeState: ObservableObject {
    static let shared = WindowThemeState()
    @Published var sidebarBackgroundColor: NSColor = NSColor(
        red: 0.96, green: 0.94, blue: 0.97, alpha: 1.0
    )
}

@main
struct ArcBrowserApp: App {
    @StateObject private var themeState = WindowThemeState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowBackgroundModifier(themeState: themeState))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Command Bar") {
                    NotificationCenter.default.post(name: .openCommandPalette, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command])
                
                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command])
                
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .windowArrangement) {
                Button("Next Space") {
                    NotificationCenter.default.post(name: .nextSpace, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])
                
                Button("Previous Space") {
                    NotificationCenter.default.post(name: .previousSpace, object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
                
                Button("Next Tab") {
                    NotificationCenter.default.post(name: .nextTab, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.command, .control])
                
                Button("Previous Tab") {
                    NotificationCenter.default.post(name: .previousTab, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.command, .control, .shift])
            }
        }
    }
}

// MARK: - Window Background Modifier
struct WindowBackgroundModifier: NSViewRepresentable {
    @ObservedObject var themeState: WindowThemeState
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.backgroundColor = themeState.sidebarBackgroundColor
                window.isOpaque = false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                // Update window background to match current theme
                window.backgroundColor = themeState.sidebarBackgroundColor
            }
        }
    }
}

// MARK: - NSColor Extension
extension NSColor {
    static func fromSwiftUIColor(_ color: Color) -> NSColor {
        // Create a platform color from SwiftUI Color
        return NSColor(color)
    }
}
extension NSNotification.Name {
    static let newTab = NSNotification.Name("ArcBrowser.newTab")
    static let closeTab = NSNotification.Name("ArcBrowser.closeTab")
    static let toggleSidebar = NSNotification.Name("ArcBrowser.toggleSidebar")
    static let nextSpace = NSNotification.Name("ArcBrowser.nextSpace")
    static let previousSpace = NSNotification.Name("ArcBrowser.previousSpace")
    static let nextTab = NSNotification.Name("ArcBrowser.nextTab")
    static let previousTab = NSNotification.Name("ArcBrowser.previousTab")
}
