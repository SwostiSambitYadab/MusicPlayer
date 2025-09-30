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
    @Environment(NavigationRoute.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.musicPlayerVisibility) private var isMiniPlayerVisible
    
    /// - For Pagination
    @AppStorage("offset") private var offset: Int = 0
    @AppStorage("totalCount") private var totalCount: Int = 0
    
    /// - All Songs
    @Query(animation: .smooth) private var songs: [Song]
    
    @State private var downloadManager: DownloadManager = .shared
    @StateObject private var moodVM: MoodSongRecommender = .shared
    
    @State private var showLikedSongs: Bool = false
    @State private var loadingState: LoadingState<[Song]> = .loading
    
    // Mood selection
    @State private var selectedMood: String = "All"
    private let moods: [String] = ["All", "Happy", "Sad", "Angry", "Calm", "Focus"]
    
    private let mockData = (0..<10).map {_ in Song.mock }
    
    var body: some View {
        List {
            Section {
                LoadingStateView(state: loadingState, mockData: mockData) { songList in
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
                            loadMoreIfNeeded(for: song)
                        }
                    }
                }
            } footer: {
                // For adding some padding for the mini music player
                if isMiniPlayerVisible.wrappedValue {
                    Color.clear
                        .frame(height: 100)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Songs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ToolBarButtons()
            }
            ToolbarItem(placement: .topBarLeading) {
                MoodMenu()
            }
        }
        .animation(.smooth, value: showLikedSongs)
        .animation(.smooth, value: selectedMood)
        .onChange(of: showLikedSongs) { _, _ in
            refreshForCurrentFilters()
        }
        .onChange(of: selectedMood) { _, newValue in
            handleMoodChange(newValue)
        }
        .task {
            // inject context for mood fetches
            moodVM.injectContext(modelContext)
            
            if songs.isEmpty {
                await fetchSongsFromServer()
            } else {
                refreshForCurrentFilters()
            }
        }
    }
}

#Preview {
    SongListView()
}

// MARK: WebService Calls & Helper Methods
extension SongListView {
    private func fetchSongsFromServer() async {
        // Only fetch from server when not filtering by mood
        guard selectedMood == "All" else {
            await fetchSongsForMoodIfNeeded()
            return
        }
        
        loadingState = .loading
        if let response = await NetworkService.shared.fetchSongsList(offset: offset),
           let musicCount = response.headers?.resultsFullCount,
           let musicList = response.results, musicList.count > 0 {
            debugPrint("Total Count", musicCount)
            totalCount = musicCount
            musicList.forEach {
                modelContext.insert($0.convertToSongs())
            }
            saveContext()
            displaySongList()
        } else {
            debugPrint("Failed to get music list from SERVER")
            loadingState = .failure("No Songs Found")
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            debugPrint("Unable to save with error:: ", error.localizedDescription)
        }
    }
    
    private func loadMoreIfNeeded(for song: Song) {
        // Do not paginate when a mood filter is active
        guard selectedMood == "All" else { return }
        let thresholdItem = songs.last
        if thresholdItem?.id == song.id, totalCount > offset {
            offset += min(totalCount - offset, 10)
            Task {
                await fetchSongsFromServer()
            }
        }
    }
    
    private func displaySongList() {
        // Base list depends on mood selection
        let baseList: [Song]
        if selectedMood == "All" {
            baseList = songs
        } else {
            switch moodVM.loadingState {
            case .success(let moodSongs):
                baseList = moodSongs
            case .failure(let message):
                loadingState = .failure(message)
                return
            case .loading:
                loadingState = .loading
                return
            }
        }
        
        // Apply liked filter if needed
        loadingState = .loading
        let filtered = showLikedSongs ? baseList.filter { $0.isFavorite } : baseList
        loadingState = filtered.isEmpty ? .failure("No Songs Found") : .success(filtered)
    }
    
    private func refreshForCurrentFilters() {
        if selectedMood == "All" {
            // Use local songs and liked filter
            displaySongList()
        } else {
            Task {
                await fetchSongsForMoodIfNeeded()
                displaySongList()
            }
        }
    }
    
    private func fetchSongsForMoodIfNeeded() async {
        // If mood is not "All", run a local fetch via SongsViaMood
        guard selectedMood != "All" else { return }
        await moodVM.fetchData(for: selectedMood)
    }
    
    private func handleMoodChange(_ mood: String) {
        // Reset pagination when switching away from "All"
        if mood != "All" {
            // Stop pagination-driven loading
            loadingState = .loading
            Task {
                await fetchSongsForMoodIfNeeded()
                displaySongList()
            }
        } else {
            // Back to "All" — show local + pagination
            displaySongList()
        }
    }
}

// MARK: View Components
extension SongListView {
    func ToolBarButtons() -> some View {
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
    
    private func MoodMenu() -> some View {
        Menu {
            Picker("Mood", selection: $selectedMood) {
                ForEach(moods, id: \.self) { mood in
                    Text(mood).tag(mood)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(selectedMood)
            }
            .font(.headline)
        }
    }
}
