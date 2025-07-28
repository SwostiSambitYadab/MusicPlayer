//
//  MusicPlayerApp.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import SwiftUI
import SwiftData

@main
struct MusicPlayerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var navigationRoute = NavigationRoute()
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationRoute.path) {
                SongListView()
                    .navigationDestination(for: AnyScreen.self) { screen in
                        screen.build()
                    }
            }
            .modelContainer(for: Song.self)
            .environmentObject(navigationRoute)
        }
    }
}
