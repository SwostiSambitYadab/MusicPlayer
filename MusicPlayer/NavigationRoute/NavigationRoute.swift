//
//  NavigationRoute.swift
//  MusicPlayer
//
//  Created by hb on 28/07/25.
//

import Foundation
import SwiftUI

struct AnyScreen: Hashable {
    private let id = UUID()
    private let viewBuilder: () -> AnyView
    
    init<V: View>(_ view: V) {
        self.viewBuilder = { AnyView(view) }
    }
    
    func build() -> AnyView {
        viewBuilder()
    }
    
    static func == (lhs: AnyScreen, rhs: AnyScreen) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


final class NavigationRoute: ObservableObject {
    @Published var path: NavigationPath = .init()
    @Published private var stacks: [AnyScreen] = []
    
    func push(_ screen: AnyScreen) {
        path.append(screen)
        stacks.append(screen)
    }
    
    func pop() {
        if path.count > 0 {
            path.removeLast()
            stacks.removeLast()
        }
    }
    
    func popBack(to screen: AnyScreen) {
        if let index = stacks.firstIndex(where: { $0 == screen }) {
            path.removeLast(path.count - (index + 1))
        }
    }
    
    func popToRoot() {
        path = .init()
        stacks = []
    }
}
