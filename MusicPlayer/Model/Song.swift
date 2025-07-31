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
    @Attribute(originalName: "localFileURL") var filePath: String = ""
    var isFavorite: Bool = false
    
    init(
        id: String,
        title: String,
        audioUrl: String,
        audioImageUrl: String,
        releasedate: String,
        duration: Int,
        downloadUrl: String,
        isDownloaded: Bool = false,
        filePath: String = "",
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.audioUrl = audioUrl
        self.audioImageUrl = audioImageUrl
        self.releasedate = releasedate
        self.duration = duration
        self.downloadUrl = downloadUrl
        self.isDownloaded = isDownloaded
        self.filePath = filePath
        self.isFavorite = isFavorite
    }
    
    static var mock: Song {
        return .init(
            id: UUID().uuidString,
            title: "Testing",
            audioUrl: "https://abcd.mp3",
            audioImageUrl: "https://image.com",
            releasedate: "2004-12-12",
            duration: 120,
            downloadUrl: "https://abcd.mp3"
        )
    }
}
