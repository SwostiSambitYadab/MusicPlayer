//
//  LoadingStateView.swift
//  MusicPlayer
//
//  Created by hb on 29/07/25.
//

import SwiftUI

enum LoadingState<T>: Equatable {
    case loading
    case success(T)
    case failure(String)
    
    var id: Int {
        switch self {
        case .loading:
            return 0
        case .success:
            return 1
        case .failure:
            return 2
        }
    }
    
    static func == (lhs: LoadingState<T>, rhs: LoadingState<T>) -> Bool {
        return lhs.id == rhs.id
    }
}

struct LoadingStateView<Content: View, T>: View {
    let state: LoadingState<T>
    let mockData: T
    let content: (T) -> Content
    
    var body: some View {
        switch state {
        case .loading:
            content(mockData)
                .redacted(reason: .placeholder)
                .shimmering()
                .allowsHitTesting(false)
        case .success(let response):
            content(response)
        case .failure(let errorMessage):
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

