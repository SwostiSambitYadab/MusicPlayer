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
    @Binding var progressDict: [String: Double]
    let onTapRow: () -> Void
    
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
                let progress = progressDict[song.id]
                if let progress, progress > 0 , progress < 1 {
                    Image(systemName: "square.fill")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(4)
                        .background(
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Color.blue, lineWidth: 4)
                                .rotationEffect(.degrees(-90))
                        )
                    
                } else {
                    Image(systemName: song.isDownloaded ? "checkmark.circle.fill"  : "arrow.down.circle.fill")
                        .font(.system(size: 22))
                        .fontWeight(.medium)
                        .foregroundStyle(song.isDownloaded ? .green : .gray)
                        .onTapGesture {
                            onTapRow()
                        }
                }
            }
        }
    }
}
