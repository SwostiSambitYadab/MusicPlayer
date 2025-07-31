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
        List {
            Section {
                ForEach(songs) { song in
                    SongListRow(song: song, downloadDict: .constant([:]))
                    .onTapGesture {
                        router.push(AnyScreen(MusicPlayerView(currentSong: song)))
                    }
                }
            } footer: {
                Color.clear
                    .frame(height: 120)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Downloads")
    }
}

#Preview {
    DownloadedSongList(songs: [])
}
