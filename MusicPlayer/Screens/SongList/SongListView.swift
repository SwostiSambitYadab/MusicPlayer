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
    @AppStorage("offset") private var offset: Int = 0
    @AppStorage("totalCount") private var totalCount: Int = 0
    
    /// - All Songs
    @Query(animation: .smooth) private var songs: [Song]
    
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
                let songList = showLikedSongs ? likedSongs : songs
                if songList.count > 0 {
                    ForEach(songList) { song in
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
                            .onAppear {
                                loadMore(song: song)
                            }
                    }
                } else {
                    Text("No Songs Found")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .frame(height: UIScreen.main.bounds.height - 320)
                        .frame(maxWidth: .infinity)
                }
            } footer: {
                // For adding some padding for the mini music player
                Color.clear
                    .frame(height: 100)
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
            if songs.isEmpty {
                await fetchSongsFromServer()
            }
        }
    }
}

#Preview {
    SongListView()
}

extension SongListView {
    func fetchSongsFromServer() async {
        if let response = await NetworkService.shared.fetchSongsList(offset: offset),
           let musicCount = response.headers?.resultsFullCount,
           let musicList = response.results, musicList.count > 0 {
            debugPrint("Total Count", musicCount)
            totalCount = musicCount
            musicList.forEach {
                modelContext.insert($0.convertToSongs())
            }
            saveContext()
        } else {
            debugPrint("Failed to get music list from SERVER")
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            debugPrint("Unable to save with error:: ", error.localizedDescription)
        }
    }
    
    private func loadMore(song: Song) {
        let thresholdItem = songs.last
        if thresholdItem?.id == song.id, totalCount > offset {
            offset += min(totalCount - offset, 10)
            Task {
                await fetchSongsFromServer()
            }
        }
    }
}
