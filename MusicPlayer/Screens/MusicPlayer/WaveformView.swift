//
//  WaveformView.swift
//  MusicPlayer
//
//  Created by hb on 14/08/25.
//

import SwiftUI

struct WaveformView: View {
    let peaks: [CGFloat]
    @Binding var progress: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let totalPeaks = peaks.count
            let playedCount = Int(progress * CGFloat(totalPeaks))
            let barWidth: CGFloat = geo.size.width / CGFloat(totalPeaks)
            let centerY = geo.size.height / 2
            
            ZStack {
                // Unplayed
                Path { path in
                    for (index, height) in peaks.enumerated() {
                        let x = CGFloat(index) * barWidth
                        path.move(to: CGPoint(x: x, y: centerY - height/2))
                        path.addLine(to: CGPoint(x: x, y: centerY + height/2))
                    }
                }
                .stroke(.gray.opacity(0.4), lineWidth: barWidth * 0.95)
                
                // Played
                Path { path in
                    for index in 0..<playedCount {
                        let height = peaks[index]
                        let x = CGFloat(index) * barWidth
                        path.move(to: CGPoint(x: x, y: centerY - height / 2))
                        path.addLine(to: CGPoint(x: x, y: centerY + height / 2))
                    }
                }
                .stroke(.green, lineWidth: barWidth * 0.95)
            }
        }
        .animation(.smooth, value: progress)
    }
}

#Preview {
    WaveformView(peaks: [], progress: .constant(0))
}
