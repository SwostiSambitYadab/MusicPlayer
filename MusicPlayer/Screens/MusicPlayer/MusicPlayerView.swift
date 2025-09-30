//
//  MusicPlayerView.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftData

struct MusicPlayerView: View {
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    @Environment(\.musicPlayerVisibility) private var musicPlayerVisibility
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRoute.self) private var router
    @StateObject private var musicPlayerManager: MusicPlayerManager = .shared
    @State private var downloadManager: DownloadManager = .shared
    let currentSong: Song
    
    private var normalizePeaks: [CGFloat] {
        return normalize(peaks: currentSong.waveform, maxHeight: 30)
    }
    
    var body: some View {
        ZStack {
            BackgroundImageLayer()
            
            if isNetworkConnected == true || currentSong.isDownloaded {
                MusicPlayerContent()
            } else {
                NoInternetView()
            }
        }
        .animation(.smooth, value: musicPlayerManager.musicProgress)
        .task {
            musicPlayerManager.checkIfSameMusicIsPlaying(currentSong)
        }
        .onAppear {
            musicPlayerVisibility.wrappedValue = false
        }
        .onDisappear {
            musicPlayerVisibility.wrappedValue = isNetworkConnected == true || currentSong.isDownloaded
        }
        .onChange(of: isNetworkConnected) { oldValue, newValue in
            if newValue == true, !currentSong.isDownloaded {
                musicPlayerManager.playStream(currSong: currentSong)
            }
        }
    }
}

// MARK: - View builders
extension MusicPlayerView {
    private func BackgroundImageLayer() -> some View {
        VStack {
            WebImage(url: URL(string: currentSong.audioImageUrl)) { image in
                image
                    .resizable()
            } placeholder: {
                Color.gray
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height / 2)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private func MusicPlayerContent() -> some View {
        VStack(spacing: 8) {
            Text(currentSong.title)
                .font(.title)
                .bold()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Released in: \(currentSong.releasedate)")
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                LikeButton()
                let downloadState = downloadManager.downloadStateDict[currentSong.id] ?? .idle
                switch downloadState {
                case .idle, .completed:
                    DownloadButton()
                case .inProgress, .paused:
                    if let progressValue = downloadState.progressValue {
                        ResumePauseDownloadSection(
                            progress: Progress(value: progressValue, isPause: downloadState.isPaused)
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            WaveformView(peaks: normalizePeaks, progress: $musicPlayerManager.musicProgress)
            .frame(height: 30)
            .gesture(DragGesture()
                .onChanged(onChangeGesture)
                .onEnded(onEndGesture)
            )
            
            HStack {
                Text(formatTime(musicPlayerManager.currentTime))
                Spacer()
                Text(formatTime(musicPlayerManager.duration))
            }
            .font(.caption)
            
            MusicPlayerPausePlayButton()
        }
        .offset(y: 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .background(.linearGradient(colors: [.clear, .gray, .black], startPoint: .top, endPoint: .bottom))
    }
    
    
    private func ResumePauseDownloadSection(progress: Progress) -> some View {
        Group {
            if progress.isPause {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
            } else {
                Image(systemName: "square.fill")
                    .font(.system(size: 14))
            }
        }
        .fontWeight(.medium)
        .foregroundStyle(.green)
        .padding(8)
        .background(
            Circle()
                .trim(from: 0, to: progress.value)
                .stroke(Color.green, lineWidth: 4)
                .rotationEffect(.degrees(-90))
        )
        .onTapGesture {
            if progress.isPause {
                downloadManager.resumeDownload(for: currentSong)
            } else {
                downloadManager.pauseDownload(for: currentSong.id)
            }
            
        }
    }
    
    private func DownloadButton() -> some View {
        Button {
            if !currentSong.isDownloaded {
                downloadManager.injectContext(modelContext)
                downloadManager.startDownload(from: currentSong)
            }
        } label: {
            Image(systemName: currentSong.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(currentSong.isDownloaded ? .green : .white)
                .font(.system(size: 22))
        }
    }
    
    private func LikeButton() -> some View {
        Button {
            currentSong.isFavorite = !currentSong.isFavorite
        } label: {
            Image(systemName: "heart.fill")
                .foregroundStyle(currentSong.isFavorite ? .green : .white)
                .font(.system(size: 22))
        }
    }
    
    private func MusicPlayerPausePlayButton() -> some View {
        Button {
            musicPlayerManager.isPlaying ? musicPlayerManager.pause() : musicPlayerManager.resume()
        } label: {
            Image(systemName: musicPlayerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
        }
        .padding(.top, 32)
    }
    
    private func NoInternetView() -> some View {
        VStack {
            Text("It seems you are not connected to internet, you can still listen downloaded songs")
                .multilineTextAlignment(.center)
                .font(.headline)
                .bold()
            
            Button {
                fetchDownloadedMusicAndRedirect()
            } label: {
                Text("Go to Downloads")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical)
                    .background(.green, in: .rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
        .offset(y: 200)
    }
}

// MARK: - Helper methods
extension MusicPlayerView {
    private func normalize(peaks: [Int], maxHeight: CGFloat) -> [CGFloat] {
        guard let maxPeak = peaks.max(), maxPeak > 0 else { return [] }
        return peaks.map { CGFloat($0) / CGFloat(maxPeak) * maxHeight }
    }
    
    private func onChangeGesture(_ gesture: DragGesture.Value) {
        let locationX = gesture.location.x
        let totalWidth = UIScreen.main.bounds.width - 32 // match padding
        let clampedX = min(max(locationX, 0), totalWidth)
        let dragProgress = clampedX / totalWidth
        
        musicPlayerManager.musicProgress = dragProgress
        
        // Also update currentTime preview while dragging
        musicPlayerManager.seek(to: dragProgress * musicPlayerManager.duration)
    }
    
    private func onEndGesture(_ gesture: DragGesture.Value) {
        musicPlayerManager.seek(to: musicPlayerManager.currentTime)
    }
    
    private func fetchDownloadedMusicAndRedirect() {
        do {
            let fetchRequest = FetchDescriptor<Song>(predicate: #Predicate { $0.isDownloaded })
            let downloadedMusicList = try modelContext.fetch(fetchRequest)
            router.push(AnyScreen(DownloadedSongList(songs: downloadedMusicList)))
        } catch {
            router.push(AnyScreen(DownloadedSongList(songs: [])))
        }
    }
}

#Preview {
    MusicPlayerView(currentSong: Song(
        id: UUID().uuidString,
        title: "Hello",
        audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        audioImageUrl: "",
        releasedate: "23/09/2022",
        duration: 110,
        downloadUrl: "https://prod-1.storage.jamendo.com/download/track/168/mp32/"
    ))
}
