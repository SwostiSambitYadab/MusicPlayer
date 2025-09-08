//
//  AppIntent.swift
//  SOSWidget
//
//  Created by hb on 03/09/25.
//

import WidgetKit
import AppIntents
import MediaPlayer

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }
}

struct TogglePlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Play/Pause"
    static var description: IntentDescription? = IntentDescription("Toggle playback in the MusicPlayer")
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        if WidgetDefaultManager.sharedPlaybackState != nil {
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            let name = CFNotificationName("com.myapp.togglePlayback" as CFString)
            CFNotificationCenterPostNotification(center, name, nil, nil, true)
        }
        return .result()
    }
}
