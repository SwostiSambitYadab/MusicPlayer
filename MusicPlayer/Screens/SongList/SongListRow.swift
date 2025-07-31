//
//  SongListRow.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct SongListRow: View {
    
    @State private var didTapDownload: Bool = false
    @Binding private var progressDict: [String: Progress]
    private let song: Song
    private let onTapPauseResume: ((_ isPause: Bool) -> Void)?
    private let onTapDownload: (() -> Void)?
    private let progress: Progress
    
    init(song: Song, progressDict: Binding<[String: Progress]>, onTapPauseResume: ((_ isPause: Bool) -> Void)? = nil, onTapDownload: (() -> Void)? = nil) {
        self.song = song
        _progressDict = progressDict
        self.onTapPauseResume = onTapPauseResume
        self.onTapDownload = onTapDownload
        self.progress = progressDict.wrappedValue[song.id] ?? Progress(value: 0, isPause: false)
    }
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: song.audioImageUrl))
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(.white, in: .rect(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(song.releasedate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            Group {
                if didTapDownload || (progress.value > 0 && progress.value < 1) {
                    ResumePauseDownloadSection(progress: progress)
                        .onTapGesture {
                            onTapPauseResume?(progress.isPause)
                        }
                } else {
                    Image(systemName: song.isDownloaded ? "checkmark.circle.fill"  : "arrow.down.circle.fill")
                        .font(.system(size: 22))
                        .fontWeight(.medium)
                        .foregroundStyle(song.isDownloaded ? .green : .gray)
                        .onTapGesture {
                            didTapDownload = true
                            onTapDownload?()
                        }
                }
            }
            .onChange(of: progress) { oldValue, newValue in
                if newValue.value == 1 {
                    didTapDownload = false
                }
            }
        }
    }
}

extension SongListRow {
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
