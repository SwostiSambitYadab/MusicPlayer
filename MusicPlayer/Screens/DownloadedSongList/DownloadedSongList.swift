//
//  DownloadedSongList.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import SwiftUI
import SwiftData

struct DownloadedSongList: View {
    @Environment(NavigationRoute.self) private var router
    @Environment(\.musicPlayerVisibility) private var isMiniPlayerVisible
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
                if isMiniPlayerVisible.wrappedValue {
                    Color.clear
                        .frame(height: 100)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Downloads")
    }
}

#Preview {
    DownloadedSongList(songs: [])
}
