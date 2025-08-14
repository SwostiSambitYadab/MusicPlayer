//
//  SentimentAnalyzer.swift
//  MusicPlayer
//
//  Created by hb on 12/08/25.
//

import Foundation
import NaturalLanguage

class SentimentAnalyzer: ObservableObject {
    private let tagger: NLTagger
    
    init() {
        tagger = NLTagger(tagSchemes: [.sentimentScore])
    }
    
    @Published var sentimentEmoji: String = ""
    
    func analyzeSentiment(_ oldValue: String, _ newValue: String) {
        tagger.string = newValue
        let (sentimentScore, _) = tagger.tag(at: newValue.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = sentimentScore?.rawValue ?? ""
        let sentimentValue = Double(score) ?? 0
        let sentiment = Sentiment.from(score: sentimentValue)
        sentimentEmoji = sentiment.rawValue
    }
    
    enum Sentiment: String {
        case lovedIt = "🥰"
        case likedIt = "👍🏻"
        case itsOk = "🆗"
        case average = "🤔"
        case belowAverage = "🙁"
        case didNotLikeIt = "😡"
        
        static func from(score: Double) -> Sentiment {
            switch score {
            case -1.0 ..< -0.5:
                return .didNotLikeIt
                
            case -0.5 ..< -0.25:
                return .belowAverage
                
            case -0.25 ..< 0:
                return .average
                
            case 0..<0.25:
                return .itsOk
                
            case 0.25..<0.5:
                return .likedIt
            
            case 0.5...1:
                return .lovedIt
                
            default:
                return .average
            }
        }
    }
}
