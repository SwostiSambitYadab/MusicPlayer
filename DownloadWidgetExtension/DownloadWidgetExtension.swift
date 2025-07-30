//
//  DownloadWidgetExtension.swift
//  DownloadWidgetExtension
//
//  Created by hb on 29/07/25.
//

import WidgetKit
import SwiftUI

struct DownloadWidgetExtension: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: DownloadAttributes.self) { context in
                // Lock screen & Dynamic Island Expanded
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                        .background(.ultraThickMaterial)
                    
                    if !context.state.isCompleted {
                        DownloadProgressView(
                            context.state.title,
                            progress: context.state.progress,
                            isPaused: context.state.isPaused
                        )
                    } else {
                        CompletedSection()
                    }
                }
            } dynamicIsland: { context in
                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        Text("⬇️")
                    }
                    
                    DynamicIslandExpandedRegion(.trailing) {
                        Text("\(Int(context.state.progress * 100))%")
                    }
                    
                    DynamicIslandExpandedRegion(.center) {
                        Text(context.state.title)
                    }
                } compactLeading: {
                    Text("⬇️")
                } compactTrailing: {
                    Text("\(Int(context.state.progress * 100))%")
                } minimal: {
                    Text("⬇️")
                }
            }
    }
}

extension DownloadWidgetExtension {
    private func DownloadProgressView(_ title: String, progress: Double, isPaused: Bool) -> some View {
        HStack(spacing: 0) {
            Text("Downloading")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer(minLength: 4)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer(minLength: 4)
            
            if isPaused {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            } else {
                CircularProgressView(progress)
            }
        }
        .padding(.horizontal)
    }
    
    private func CompletedSection() -> some View {
        Text("Downlad Completed")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.green)
    }
    
    private func CircularProgressView(_ progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(.gray, lineWidth: 4)
                .frame(width: 30, height: 30)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(.green, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 30)
                .animation(.easeOut, value: progress)
        }
    }
}
