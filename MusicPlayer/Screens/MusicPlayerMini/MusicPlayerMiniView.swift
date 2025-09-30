//
//  MusicPlayerMiniView.swift
//  MusicPlayer
//
//  Created by hb on 29/07/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct MusicPlayerMiniView: View {
    @StateObject private var vm: MusicPlayerManager = .shared
    @Environment(\.musicPlayerVisibility) private var visibility
    @Environment(NavigationRoute.self) private var router
    
    var body: some View {
        HStack {
            MusicThumbnail()
            
            MusicDetails()
            
            Spacer(minLength: 8)
            
            PlayPauseButton()
        }
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
        .onTapGesture {
            router.push(AnyScreen(MusicPlayerView(currentSong: vm.currentSong ?? .mock)))
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    MusicPlayerMiniView()
}

extension MusicPlayerMiniView {
    private func MusicThumbnail() -> some View {
        WebImage(url: URL(string: vm.currentSong?.audioImageUrl ?? "")) { image in
            image
                .resizable()
                .frame(width: 100, height: 100)
                .scaledToFill()
                .clipShape(.rect(cornerRadius: 12))
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray)
                .frame(width: 100, height: 100)
        }
    }
    
    private func MusicDetails() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.currentSong?.title ?? "")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
                .lineLimit(2)
            
            Text(vm.currentSong?.releasedate ?? "")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.green.opacity(0.8))
        }
    }
    
    private func PlayPauseButton() -> some View {
        Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 32))
            .bold()
            .foregroundStyle(.green)
            .onTapGesture {
                if vm.isPlaying {
                    vm.pause()
                } else {
                    vm.resume()
                }
            }
    }
    
    private func CloseButton() -> some View {
        Button {
            MusicPlayerManager.shared.cleanup()
            visibility.wrappedValue = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .offset(x: 6, y: -6)
    }
}
