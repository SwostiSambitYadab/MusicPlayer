//
//  SOSWidget.swift
//  SOSWidget
//
//  Created by hb on 03/09/25.
//

import WidgetKit
import SwiftUI

struct MusicEntry: TimelineEntry {
    let date: Date
    let state: SharedPlaybackState?
    let artwork: UIImage?
}

struct MusicProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MusicEntry {
        MusicEntry(date: Date(), state: nil, artwork: nil)
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> MusicEntry {
        loadEntry()
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<MusicEntry> {
        return Timeline(entries: [loadEntry()], policy: .atEnd)
    }
    
    private func loadEntry() -> MusicEntry {
        guard let state = WidgetDefaultManager.sharedPlaybackState else {
            return .init(date: .now, state: nil, artwork: nil)
        }
        
        var artworkImage: UIImage? = nil
        if let imageData = WidgetDefaultManager.shared.getArtworkImageData(from: state.artworkFilename ?? "") {
            artworkImage = UIImage(data: imageData)
        }
        
        return MusicEntry(date: .now, state: state, artwork: artworkImage)
    }
}

/// - Music Widget View
struct MusicWidgetEntryView: View {
    var entry: MusicEntry

    var body: some View {
        VStack(alignment: .center) {
            if let img = entry.artwork {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 60)
                    .clipped()
            } else {
                Color.gray.frame(width: 60, height: 60)
            }
            Text(entry.state?.title ?? "No track")
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.white)
            Button(intent: TogglePlayPauseIntent()) {
                Image(systemName: entry.state?.isPlaying == true ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
        }
        .padding()
        .containerBackground(.black.opacity(0.7), for: .widget)
    }
}

struct MusicWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetConstant.kind, provider: MusicProvider(), content: { entry in
            MusicWidgetEntryView(entry: entry)
        })
        .configurationDisplayName("Music")
        .description("Quickly play music.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
