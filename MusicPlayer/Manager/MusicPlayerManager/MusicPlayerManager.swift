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
    private var artworkImage: MPMediaItemArtwork?
    
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
        
        /// - For Resuming
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.resume()
            return .success
        }
        
        /// - For Pausing
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
        
        /// - For seeking with slider
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
        
        /// - For seeking forward
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            self?.skipForward()
            return .success
        }
        
        /// - For seeking backward
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            self?.skipBackward()
            return .success
        }
    }
    
    func cleanup() {
        player?.pause()
        player = nil
    }
    
    private func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func skipForward() {
        let maxDuration = player?.currentItem?.duration.seconds ?? 0
        let seekDuration = (player?.currentTime().seconds ?? 0) + 15
        let newTime = min(maxDuration, seekDuration)
        let cmTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    private func skipBackward() {
        let seekDuration = (player?.currentTime().seconds ?? 0) - 15
        let newTime = max(0, seekDuration)
        let cmTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player?.seek(to: cmTime)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
}

extension MusicPlayerManager {
    func playStream(currSong: Song) {
        // cleaning up before starting new track
        cleanup()
        // taking url from localFile if downloaded
        let urlString = currSong.isDownloaded ? currSong.localFileURL : currSong.audioUrl
        debugPrint("Playing URL: \(urlString)")
        guard let url = URL(string: urlString) else { return }
        currentSong = currSong
        
        // setting up player
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
            // downloading artwork from server if not already
            nowPlayingInfo[MPMediaItemPropertyArtwork] = await downloadArtWorkURL()
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentSong?.duration ?? 0
            if let rate = player?.rate {
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
            }
            
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
            if let artworkImage {
                return artworkImage
            }
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
