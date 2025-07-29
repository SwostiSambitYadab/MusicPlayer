//
//  SongListView.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import SwiftUI
import SwiftData
import SDWebImageSwiftUI

struct SongListView: View {
    @EnvironmentObject private var router: NavigationRoute
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [.init(\Song.id, order: .reverse)], animation: .smooth) private var songs: [Song]
    @StateObject private var downloadManager: DownloadManager = .shared
    
    var body: some View {
        List(songs, id: \.id) { song in
            SongListRow(
                song: song,
                progressDict: $downloadManager.progressDict) { isPause in
                    if isPause {
                        downloadManager.resumeDownload(for: song)
                    } else {
                        downloadManager.pauseDownload(for: song.id)
                    }
                } onTapDownload: {
                    if !song.isDownloaded {
                        downloadManager.injectContext(modelContext)
                        downloadManager.startDownload(from: song)
                    }
                }
                .onTapGesture {
                    router.push(AnyScreen(MusicPlayerView(
                        currentSong: song,
                        progressDict: $downloadManager.progressDict
                    )))
                }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Songs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("Downloads")
                    .font(.headline)
                    .bold()
                    .onTapGesture {
                        let downloadedSongs = songs.filter { $0.isDownloaded }
                        router.push(AnyScreen(DownloadedSongList(songs: downloadedSongs)))
                    }
            }
        }
        .task {
            await fetchSongsFromServer()
        }
        .onAppear {
            MusicPlayerManager.shared.cleanup()
        }
    }
}

#Preview {
    SongListView()
}

extension SongListView {
    func fetchSongsFromServer() async {
        if songs.isEmpty {
            if let response = await NetworkService.shared.fetchSongsList(),
               let musicList = response.results, musicList.count > 0 {
                debugPrint("RESPONSE", musicList)
                musicList.forEach {
                    modelContext.insert($0.convertToSongs())
                }
                saveContext()
            } else {
                debugPrint("Failed to get music list from SERVER")
            }
        }
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            debugPrint("Unable to save with error:: ", error.localizedDescription)
        }
    }
}
