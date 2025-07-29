//
//  NetworService.swift
//  MusicPlayer
//
//  Created by hb on 25/07/25.
//

import Foundation

final class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    func fetchSongsList() async -> MusicListModel? {
        let clientID = "3d80b7b0"
        let baseURLString = "https://api.jamendo.com/v3.0/tracks/?client_id=\(clientID)&format=json&limit=10"
        
        guard let baseURL = URL(string: baseURLString) else { return nil }
        let request = URLRequest(url: baseURL)
        debugPrint("REQUEST", request)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return nil }
            debugPrint("RESPONSE: ", response)
            if response.statusCode < 299 && response.statusCode >= 200 {
                let decoder = JSONDecoder()
                let musicListData = try decoder.decode(MusicListModel.self, from: data)
                return musicListData
            } else {
                debugPrint("Error in parsing data")
                return nil
            }
        } catch {
            debugPrint("Unable to Fetch the data:: ", error.localizedDescription)
            return nil
        }
    }
}
