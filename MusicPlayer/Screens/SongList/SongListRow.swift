//
//  SongListRow.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct SongListRow: View {
    
    let song: Song
    @Binding var downloadDict: [String: DownloadState]
    var onTapPauseResume: ((_ isPause: Bool) -> Void)? = nil
    var onTapDownload: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: song.audioImageUrl))
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(.white, in: .rect(cornerRadius: 16))
            
            SongDetails()
            
            Spacer(minLength: 0)
            
            DownloadStateButton()
        }
    }
}

extension SongListRow {
    
    private func SongDetails() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(song.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(song.releasedate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func DownloadStateButton() -> some View {
        let downloadState = downloadDict[song.id] ?? .idle
        
        switch downloadState {
        case .idle, .completed:
            Image(systemName: song.isDownloaded ? "checkmark.circle.fill"  : "arrow.down.circle.fill")
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundStyle(song.isDownloaded ? .green : .gray)
                .onTapGesture {
                    onTapDownload?()
                }
        case .inProgress, .paused:
            if let progressValue = downloadState.progressValue {
                ResumePauseDownloadSection(
                    progress: Progress(
                        value: progressValue,
                        isPause: downloadState.isPaused
                    )
                )
                .onTapGesture {
                    onTapPauseResume?(true)
                }
            }
        }
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
    }
}
