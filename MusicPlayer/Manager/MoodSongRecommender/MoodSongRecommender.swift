//
//  MoodSongRecommender.swift
//  MusicPlayer
//
//  Created by hb on 12/08/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class MoodSongRecommender {
    static let shared = MoodSongRecommender()
    private init() {}
    
    // Inject when you need to query SwiftData
    private var modelContext: ModelContext?
    func injectContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    var currentMood: String?
    var loadingState: LoadingState<[Song]> = .loading
    
    // Public entry point: mood can be a free-form string (e.g., "happy", "sad", "angry", "calm", "focus")
    func fetchData(for mood: String) async {
        currentMood = mood
        loadingState = .loading
        
        guard let modelContext else {
            loadingState = .failure("ModelContext not injected")
            return
        }
        
        do {
            // Build a broad descriptor (only supported predicate ops)
            let key = normalize(mood)
            let descriptor = makeBroadFetchDescriptor(for: key)
            
            // Fetch from store
            let fetched = try modelContext.fetch(descriptor)
            
            // Apply in-memory filtering for title keywords and any extra heuristics
            let filtered = filterInMemory(fetched, for: key, originalQuery: mood)
            
            loadingState = filtered.isEmpty ? .failure("No songs found for mood '\(mood)'") : .success(filtered)
        } catch {
            loadingState = .failure("Failed to fetch: \(error.localizedDescription)")
        }
    }
}

// MARK: - Mood → Heuristics and filtering
private extension MoodSongRecommender {
    // Only use supported comparisons inside FetchDescriptor predicate
    func makeBroadFetchDescriptor(for moodKey: String) -> FetchDescriptor<Song> {
        switch moodKey {
        case "happy", "love", "joy":
            // Prefer shorter to mid songs via duration
            return FetchDescriptor<Song>(
                predicate: #Predicate { song in
                    song.duration <= 300
                },
                sortBy: [SortDescriptor(\.duration, order: .forward)]
            )
        case "sad", "blue":
            // Prefer longer songs
            return FetchDescriptor<Song>(
                predicate: #Predicate { song in
                    song.duration >= 180
                },
                sortBy: [SortDescriptor(\.duration, order: .reverse)]
            )
        case "angry", "rage":
            // No string ops; just a loose duration gate
            return FetchDescriptor<Song>(
                predicate: #Predicate { song in
                    song.duration >= 150
                },
                sortBy: [SortDescriptor(\.releasedate, order: .reverse)]
            )
        case "calm", "chill", "relax", "focus":
            // Mid/long duration
            return FetchDescriptor<Song>(
                predicate: #Predicate { song in
                    song.duration >= 180 && song.duration <= 420
                },
                sortBy: [SortDescriptor(\.duration, order: .forward)]
            )
        default:
            // Fallback: fetch all, sort by title; keyword filtering happens in-memory
            return FetchDescriptor<Song>(
                sortBy: [SortDescriptor(\.title, order: .forward)]
            )
        }
    }
    
    // Apply keyword/title checks in memory using localized contains (not allowed in #Predicate)
    func filterInMemory(_ songs: [Song], for moodKey: String, originalQuery: String) -> [Song] {
        // Keyword sets
        let upbeatKeywords = ["love", "happy", "sun", "smile", "dance", "party", "joy", "good", "fun"]
        let mellowKeywords = ["sad", "blue", "tears", "slow", "lonely", "night", "rain"]
        let energyKeywords = ["fire", "rage", "hard", "fast", "fight", "storm", "power"]
        let calmKeywords = ["calm", "chill", "lofi", "soft", "relax", "peace", "ambient", "focus"]
        
        func titleMatchesAny(_ keywords: [String], title: String) -> Bool {
            for kw in keywords {
                if title.localizedCaseInsensitiveContains(kw) { return true }
            }
            return false
        }
        
        switch moodKey {
        case "happy", "love", "joy":
            // Prefer upbeat titles, otherwise keep duration gate effect
            let candidates = songs
            let scored = candidates.map { song -> (Song, Int) in
                let score = (song.duration <= 240 ? 1 : 0) + (titleMatchesAny(upbeatKeywords, title: song.title) ? 2 : 0)
                return (song, score)
            }
            return scored
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                    return lhs.0.duration < rhs.0.duration
                }
                .map { $0.0 }
            
        case "sad", "blue":
            let candidates = songs
            let scored = candidates.map { song -> (Song, Int) in
                let score = (song.duration >= 200 ? 2 : 0) + (titleMatchesAny(mellowKeywords, title: song.title) ? 2 : 0)
                return (song, score)
            }
            return scored
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                    return lhs.0.duration > rhs.0.duration
                }
                .map { $0.0 }
            
        case "angry", "rage":
            let candidates = songs
            let scored = candidates.map { song -> (Song, Int) in
                let score = (song.duration >= 150 ? 1 : 0) + (titleMatchesAny(energyKeywords, title: song.title) ? 2 : 0)
                return (song, score)
            }
            return scored
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                    return lhs.0.duration > rhs.0.duration
                }
                .map { $0.0 }
            
        case "calm", "chill", "relax", "focus":
            let candidates = songs
            let scored = candidates.map { song -> (Song, Int) in
                let inRange = (song.duration >= 180 && song.duration <= 420) ? 1 : 0
                let titleScore = titleMatchesAny(calmKeywords, title: song.title) ? 2 : 0
                return (song, inRange + titleScore)
            }
            return scored
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                    return lhs.0.duration < rhs.0.duration
                }
                .map { $0.0 }
            
        default:
            // Fallback: keyword search in title using the original query
            let trimmed = originalQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return songs }
            return songs.filter { $0.title.localizedStandardContains(trimmed) }
        }
    }
    
    func normalize(_ mood: String) -> String {
        let trimmed = mood.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
            // Support emoji inputs by mapping to simple mood buckets
        case "🥰", "👍🏻", "🆗", "🤔", "🙁", "😡":
            if trimmed == "🥰" || trimmed == "👍🏻" { return "happy" }
            if trimmed == "🙁" { return "sad" }
            if trimmed == "😡" { return "angry" }
            if trimmed == "🤔" || trimmed == "🆗" { return "calm" }
            return "calm"
        default:
            return trimmed
        }
    }
}
