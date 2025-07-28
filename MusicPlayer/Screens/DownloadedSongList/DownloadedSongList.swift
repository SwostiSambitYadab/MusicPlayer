//
//  DownloadedSongList.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import SwiftUI
import SwiftData

struct DownloadedSongList: View {
    @EnvironmentObject private var router: NavigationRoute
    let songs: [Song]
    
    var body: some View {
        List(songs, id: \.id) { song in
            SongListRow(song: song, progressDict: .constant([:])) {
                debugPrint("Tapped downloaded row")
            }
            .onTapGesture {
                router.push(AnyScreen(MusicPlayerView(currentSong: song, progressDict: .constant([:]))))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Downloads")
    }
}

#Preview {
    DownloadedSongList(songs: [])
}
