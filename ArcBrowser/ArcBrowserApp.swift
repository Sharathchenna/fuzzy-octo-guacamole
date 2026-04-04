//
//  ArcBrowserApp.swift
//  ArcBrowser
//
//  Created by Sharath Chenna on 04/04/26.
//

import SwiftUI

@main
struct ArcBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Command Bar") {
                    NotificationCenter.default.post(name: .openCommandPalette, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
        }
    }
}
