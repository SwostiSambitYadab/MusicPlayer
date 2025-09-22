//
//  SharedPlaybackState.swift
//  MusicPlayer
//
//  Created by hb on 08/09/25.
//

import Foundation

enum WidgetConstant {
    static let appGroupID = "group.com.blelearning.app.widget"
    static let kind = "MusicWidget"
}

enum WidgetKeys {
    static let sharedPlaybackState = "shared_playback_state"
}

struct SharedPlaybackState: Codable {
    let id: String?
    let title: String?
    var isPlaying: Bool
    let currentTime: Double
    let duration: Int
    let artworkFilename: String?
    let updatedAt: Date
}

struct WidgetDefaultManager {
    static let shared = WidgetDefaultManager()
    private init() {}
    
    static let widgetDefaults = UserDefaults(suiteName: WidgetConstant.appGroupID)
 
    static func setSharedPlaybackState(state: SharedPlaybackState) {
        let encoder = JSONEncoder()
        let encodedData = try? encoder.encode(state)
        widgetDefaults?.setValue(encodedData, forKey: WidgetKeys.sharedPlaybackState)
        widgetDefaults?.synchronize()
    }
    
    static var sharedPlaybackState: SharedPlaybackState? {
        if let d = widgetDefaults?.object(forKey: WidgetKeys.sharedPlaybackState) as? Data {
            let decoder = JSONDecoder()
            let decodedState = try? decoder.decode(SharedPlaybackState.self, from: d)
            return decodedState
        }
        return nil
    }
    
    static func removeAll() {
        widgetDefaults?.removeObject(forKey: WidgetKeys.sharedPlaybackState)
    }
    
    func sharedContainerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetConstant.appGroupID)
    }
    
    func getArtworkImageData(from filename: String) -> Data? {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetConstant.appGroupID) {
            let url = container.appendingPathComponent(filename, conformingTo: .image)
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }
        return nil
    }
}
