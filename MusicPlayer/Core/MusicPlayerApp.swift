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
    @State private var navigationRoute = NavigationRoute()
    @State private var networkMonitor = NetworkMonitor()
    @State private var musicPlayerVisibility: Bool = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationRoute.path) {
                SongListView()
                    .navigationDestination(for: AnyScreen.self) { screen in
                        screen.build()
                    }
            }
            .overlay(alignment: .bottom) {
                MusicPlayerMiniView()
                    .offset(y: musicPlayerVisibility ? 20 : 300)
                    .transition(.push(from: .bottom))
            }
            .animation(.easeIn(duration: 0.25), value: musicPlayerVisibility)
            .environment(\.musicPlayerVisibility, $musicPlayerVisibility)
            .environment(\.isNetworkConnected, networkMonitor.isConnected)
            .modelContainer(for: Song.self)
            // Use Observation environment injection for NavigationRoute
            .environment(navigationRoute)
            .preferredColorScheme(.dark)
        }
    }
}
