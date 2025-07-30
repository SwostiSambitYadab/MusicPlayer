//
//  DownloadAttributes.swift
//  MusicPlayer
//
//  Created by hb on 29/07/25.
//

import ActivityKit

struct DownloadAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var title: String
        var isCompleted: Bool = false
        var isPaused: Bool = false
    }
    let songID: String
    let songTitle: String
}

