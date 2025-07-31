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
    
    /// - All Songs
    @Query(sort: [.init(\Song.id, order: .reverse)], animation: .smooth) private var songs: [Song]
    
    /// - Liked Songs
    @Query(
        filter: #Predicate<Song> { $0.isFavorite },
        sort: [.init(\Song.id,order: .reverse)],
        animation: .smooth
    ) private var likedSongs: [Song]
    @StateObject private var downloadManager: DownloadManager = .shared
    @State private var showLikedSongs: Bool = false
    
    var body: some View {
        List {
            Section {
                ForEach(showLikedSongs ? likedSongs : songs) { song in
                    SongListRow(song: song, downloadDict: $downloadManager.downloadStateDict) { isPause in
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
                            router.push(AnyScreen(MusicPlayerView(currentSong: song)))
                        }
                }
            } footer: {
                // For adding some padding for the mini music player
                Color.clear
                    .frame(height: 120)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Songs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(showLikedSongs ? .green : .white)
                        .font(.headline)
                        .bold()
                        .onTapGesture {
                            showLikedSongs.toggle()
                        }
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.headline)
                        .bold()
                        .onTapGesture {
                            let downloadedSongs = songs.filter { $0.isDownloaded }
                            router.push(AnyScreen(DownloadedSongList(songs: downloadedSongs)))
                        }
                }
            }
        }
        .animation(.smooth, value: showLikedSongs)
        .task {
            await fetchSongsFromServer()
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
