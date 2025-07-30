//
//  AppDelegate.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import UIKit
import AVKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupAudioSession()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                debugPrint("Notifications allowed")
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("🌙 Resuming: \(identifier)")
        DownloadManager.shared.backgroundCompletionHandler = completionHandler
    }
}

extension AppDelegate {
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
        } catch {
            debugPrint("Unable to setup Audio session with error:: ", error.localizedDescription)
        }
    }
}
