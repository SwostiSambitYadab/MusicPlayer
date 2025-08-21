//
//  Utility.swift
//  MusicPlayer
//
//  Created by hb on 14/08/25.
//

import Foundation
import SwiftUICore
import Network

extension EnvironmentValues {
    @Entry var musicPlayerVisibility: Binding<Bool> = .constant(false)
    @Entry var isNetworkConnected: Bool?
    @Entry var connectionType: NWInterface.InterfaceType?
}

public func formatTime(_ time: Double) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}
