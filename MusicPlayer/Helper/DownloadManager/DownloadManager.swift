//
//  DownloadManager.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import Foundation
import SwiftData

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    private var backgroundSession: URLSession!
    private var modelContext: ModelContext?
    
    /// Progress Dict to show download progress
    @Published var progressDict: [String: Double] = [:]
    
    var backgroundCompletionHandler: (() -> Void)?
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.music_player.download")
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
    func startDownload(from song: Song) {
        guard let url = URL(string: song.downloadUrl) else { return }
        let task = backgroundSession.downloadTask(with: url)
        task.taskDescription = song.id
        task.resume()
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documents.appendingPathComponent(downloadTask.response?.suggestedFilename ?? UUID().uuidString)
        
        do {
            if fileManager.fileExists(atPath: destination.path()) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: location, to: destination)
            debugPrint("✅ File Saved to \(destination)")
            
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
        debugPrint("📦 Downloading: \(totalBytesWritten) / \(totalBytesExpectedToWrite)")
        guard let songID = downloadTask.taskDescription else { return }
        DispatchQueue.main.async {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progressDict[songID] = progress
        }
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
            existingSong.localFileURL = destination.description
            debugPrint("BEFORE Update:: ", existingSong)
            DispatchQueue.main.async {
                self.saveContext()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    debugPrint("AFTER UPDATE:: ", existingSong)
                }
            }
        }
    }
    
    private func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            debugPrint("Failed to save context: ", error.localizedDescription)
        }
    }
}
