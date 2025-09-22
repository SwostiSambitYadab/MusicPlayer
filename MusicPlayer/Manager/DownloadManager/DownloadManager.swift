//
//  DownloadManager.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import Foundation
import SwiftData
import ActivityKit

struct Progress {
    let value: Double
    var isPause: Bool
}

enum DownladState {
    case idle
    case started
    case paused(Double)
    case inProgress(Double)
    case completed
    
    var isPaused: Bool {
        if case .paused(_) = self { return true }
        return false
    }
}

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    private var backgroundSession: URLSession!
    private var modelContext: ModelContext?
    
    /// - Progress Dict to show download progress
    private var progressDict: [String: Double] = [:]
    @Published var downloadStateDict: [String: DownladState] = [:]
    
    /// - For Live Activity
    private var activities: [Activity<DownloadAttributes>] = []
    private var songMetaData: [String: Song] = [:]
    
    /// - To Pause/Resume Download Tasks
    private var activeDownloads: [String: URLSessionDownloadTask] = [:]
    private var resumeDataDict: [String: Data] = [:]
    
    var backgroundCompletionHandler: (() -> Void)?
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.music_player.download.\(UUID().uuidString)")
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /// - Injecting ModelContext of Songs
    func injectContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// - For Starting the download of the song
    /// Stored songId in downloadTask's task description .
    /// Used the songId in updating swiftData after download and updating progress
    /// "https://speedtest.tokyo2.linode.com/100MB-tokyo.bin"
    func startDownload(from song: Song) {
        guard let url = URL(string: song.downloadUrl) else { return }
        let task = backgroundSession.downloadTask(with: url)
        task.taskDescription = song.id
        songMetaData[song.id] = song
        activeDownloads[song.id] = task
        downloadStateDict[song.id] = .started
        task.resume()
        
        // start Live Activity
        startLiveActivity(for: song)
    }
    
    /// - For Pausing Download
    func pauseDownload(for songID: String) {
        guard let task = activeDownloads[songID] else { return }
        task.cancel { [weak self] resumeData in
            guard let `self` else { return }
            resumeDataDict[songID] = resumeData
            activeDownloads[songID] = nil
            
            let songTitle = songMetaData[songID]?.title ?? ""
            let contentState = DownloadAttributes.ContentState(progress: progressDict[songID] ?? 0.0, title: songTitle, isPaused: true)
            Task {
                if let activity = self.activities.first(where: { $0.attributes.songID == songID }) {
                    await activity.update(ActivityContent(state: contentState, staleDate: nil))
                }
            }
            
            DispatchQueue.main.async {
                self.downloadStateDict[songID] = .paused(self.progressDict[songID] ?? 0)
            }
            debugPrint("⏸ Paused download for: \(songID)")
        }
    }
    
    /// - For Resuming Download
    func resumeDownload(for song: Song) {
        guard let resumeData = resumeDataDict[song.id] else {
            // Fallback if not found any resumeData
            startDownload(from: song)
            downloadStateDict[song.id] = .started
            return
        }
        let task = backgroundSession.downloadTask(withResumeData: resumeData)
        task.taskDescription = song.id
        activeDownloads[song.id] = task
        resumeDataDict[song.id] = nil
        downloadStateDict[song.id] = .inProgress(progressDict[song.id] ?? 0.0)
        updateLiveActivity(for: song.id, progress: progressDict[song.id] ?? 0.0)
        task.resume()
        debugPrint("🔁 Resumed download for: \(song.id)")
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documents.appendingPathComponent(downloadTask.response?.suggestedFilename ?? UUID().uuidString)
        
        do {
            // checking if file already exists
            if fileManager.fileExists(atPath: destination.path()) {
                try fileManager.removeItem(at: destination)
            }
            
            // saving file in the destination location
            try fileManager.moveItem(at: location, to: destination)
            debugPrint("✅ File Saved to \(destination)")
            
            // ending after completed state of Live Activity
            endLiveActivity(for: downloadTask.taskDescription ?? "")
             
            // update swift Data
            try updateSwiftData(destination: destination, downloadTask: downloadTask)
            
        } catch {
            debugPrint("File moving failed: ", error.localizedDescription)
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        debugPrint("📦 PROGRESS \(downloadTask.accessibilityValue ?? "") : \(progress)")
        
        // updating the progress block in the dictionary
        guard let songID = downloadTask.taskDescription else { return }
        DispatchQueue.main.async {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progressDict[songID] = progress
            self.downloadStateDict[songID] = .inProgress(progress)
        }
        updateLiveActivity(for: songID, progress: progress)
    }
}

extension DownloadManager {
    /// - Updating the swiftData for songs for the particular download Request
    private func updateSwiftData(destination: URL, downloadTask: URLSessionDownloadTask) throws {
        guard let modelContext,
              let songID = downloadTask.taskDescription else { return }
        
        let fetchRequest = FetchDescriptor<Song>(predicate: #Predicate { $0.id == songID })
        
        if let existingSong = try modelContext.fetch(fetchRequest).first {
            existingSong.isDownloaded = true
            existingSong.filePath = destination.lastPathComponent
            DispatchQueue.main.async {
                self.downloadStateDict[downloadTask.taskDescription ?? ""] = .completed
                self.saveContext()
            }
        }
    }
    
    /// - Saving model context
    private func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            debugPrint("Failed to save context: ", error.localizedDescription)
        }
    }
}

/// - For Live Activity
extension DownloadManager {
    private func startLiveActivity(for song: Song) {
        let attributes = DownloadAttributes(songID: song.id, songTitle: song.title)
        let contentState = DownloadAttributes.ContentState(progress: 0.0, title: song.title)
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            do {
                if !activities.contains(where: { $0.attributes.songID == song.id }) {
                    let activity = try Activity<DownloadAttributes>.request(attributes: attributes, content: activityContent)
                    debugPrint(activity)
                    activities.append(activity)
                }
            } catch {
                debugPrint("Live Activity Failed: ", error.localizedDescription)
            }
        }
    }
    
    private func updateLiveActivity(for songID: String, progress: Double ) {
        let songTitle = songMetaData[songID]?.title ?? ""
        let contentState = DownloadAttributes.ContentState(progress: progress, title: songTitle)
        Task {
            if let activity = activities.first(where: { $0.attributes.songID == songID }) {
                await activity.update(ActivityContent(state: contentState, staleDate: nil))
            }
        }
    }
    
    private func endLiveActivity(for songID: String) {
        let songTitle = songMetaData[songID]?.title ?? ""
        let completedState = DownloadAttributes.ContentState(progress: 1.0, title: songTitle, isCompleted: true)
        Task {
            if let activity = activities.first(where: { $0.attributes.songID == songID }) {
                await activity.end(ActivityContent(state: completedState, staleDate: nil), dismissalPolicy: .after(.now.addingTimeInterval(2.0)))
                activities.removeAll(where: { $0.attributes.songID == activity.attributes.songID })
            }
        }
    }
}
