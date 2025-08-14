//
//  SentimentView.swift
//  MusicPlayer
//
//  Created by hb on 12/08/25.
//

import SwiftUI

struct SentimentView: View {
    
    @StateObject private var analyzer: SentimentAnalyzer = .init()
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Analyze sentiment")
                .font(.headline)
                .foregroundStyle(.gray)
            
            TextEditor(text: $inputText)
            
            Text(analyzer.sentimentEmoji)
                .font(.subheadline)
        }
        .onChange(of: inputText, analyzer.analyzeSentiment)
    }
}

#Preview {
    SentimentView()
}
