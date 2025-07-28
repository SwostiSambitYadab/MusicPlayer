//
//  MusicPlayerManager.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import Foundation
import AVKit
import MediaPlayer

class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()
    
    private var player: AVPlayer?
    private var timerObservationToken: Any?
    private var currentSong: Song?
    
    @Published var isPlaying = false
    
    private init() {
        setupRemoteTransportControls()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            debugPrint("Failed to start Audio Session with error:: ", error.localizedDescription)
        }
    }
    
    /// - For handling play pause from Notification Pannel
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
    }
    
    
    func cleanup() {
        player?.pause()
        player = nil
    }
}

extension MusicPlayerManager {
    func playStream(currSong: Song) {
        // cleaning up before starting new track
        cleanup()
        // taking url from localFile if downloaded
        let urlString = currSong.isDownloaded ? currSong.localFileURL : currSong.audioUrl
        debugPrint("AUDIO URL: \(urlString)")
        guard let url = URL(string: urlString) else { return }
        currentSong = currSong
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    func resume() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    /// - Updating the playingInfo in Notification Center
    private func updateNowPlayingInfo() {
        Task {
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentSong?.title ?? "Sample Audio"
            nowPlayingInfo[MPMediaItemPropertyArtwork] = await downloadArtWorkURL()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentSong?.duration ?? 0
            
            if let currentTime = player?.currentTime() {
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(currentTime)
            }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    /// - Downloading thumbnail image from server
    private func downloadArtWorkURL()async -> MPMediaItemArtwork? {
        guard let url = URL(string: currentSong?.audioImageUrl ?? "") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            if let image = UIImage(data: data) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                return artwork
            }
        } catch {
            debugPrint("Error in downloading image", url)
            return nil
        }
        return nil
    }
}
