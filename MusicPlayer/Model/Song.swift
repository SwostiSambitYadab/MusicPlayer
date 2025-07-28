//
//  Songs.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import Foundation
import SwiftData

@Model
class Song {
    @Attribute(.unique) var id: String
    var title: String
    var audioUrl: String
    var audioImageUrl: String
    var releasedate: String
    var duration: Int
    var downloadUrl: String
    var isDownloaded: Bool = false
    var localFileURL: String
    
    init(id: String, title: String, audioUrl: String, audioImageUrl: String, releasedate: String, duration: Int, downloadUrl: String, isDownloaded: Bool = false, localFileUrl: String = "") {
        self.id = id
        self.title = title
        self.audioUrl = audioUrl
        self.audioImageUrl = audioImageUrl
        self.releasedate = releasedate
        self.duration = duration
        self.downloadUrl = downloadUrl
        self.isDownloaded = isDownloaded
        self.localFileURL = localFileUrl
    }
}
