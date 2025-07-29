//
//  LoadingStateView.swift
//  MusicPlayer
//
//  Created by hb on 29/07/25.
//

import SwiftUI

enum LoadingState<T> {
    case idle
    case loading
    case success(T)
    case Failure(String)
}

struct LoadingStateView<Content: View, T>: View {
    let state: LoadingState<T>
    let mockData: T
    let content: (T) -> Content
    
    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            content(mockData)
                .redacted(reason: .placeholder)
                .shimmering()
                .allowsHitTesting(false)
        case .success(let response):
            content(response)
        case .Failure(let errorMessage):
            Text(errorMessage)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    @Previewable
    @State var loadingState: LoadingState<[String]> = .loading
    
    LoadingStateView(state: loadingState, mockData: ["------------", "----------------------"]) { values in
        List(values, id: \.self) { value in
            Text(value)
        }
        .listStyle(.insetGrouped)
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            loadingState = .success(["Hello how are you", "I know where are you"])
        }
    }
}

