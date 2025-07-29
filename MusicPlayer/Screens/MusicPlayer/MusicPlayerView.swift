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
    @Environment(\.modelContext) private var modelContext
    @StateObject private var musicPlayerManager: MusicPlayerManager = .shared
    @StateObject private var downloadManager: DownloadManager = .shared
    let currentSong: Song
    @Binding var progressDict: [String: Progress]
    
    var body: some View {
        ZStack {
            BackgroundImageLayer()
            
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
                    
                    Group {
                        let progress = progressDict[currentSong.id]
                        if let progress, progress.value > 0 , progress.value < 1 {
                            ResumePauseDownloadSection(progress: progress)
                        } else {
                            DownloadButton()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MusicPlayerPausePlayButton()
            }
            .offset(y: 120)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .background(.linearGradient(colors: [.clear, .gray, .black], startPoint: .top, endPoint: .bottom))
        }
        .task {
            musicPlayerManager.playStream(currSong: currentSong)
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
        downloadUrl: "https://prod-1.storage.jamendo.com/download/track/168/mp32/",
        localFileUrl: ""
    ), progressDict: .constant([:]))
}

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
        .foregroundStyle(.blue)
        .padding(8)
        .background(
            Circle()
                .trim(from: 0, to: progress.value)
                .stroke(Color.blue, lineWidth: 4)
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
            
        } label: {
            Image(systemName: "heart.fill")
                .foregroundStyle(.green)
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
}
