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
