//
//  NetworkMonitor.swift
//  MusicPlayer
//
//  Created by hb on 14/08/25.
//

import Foundation
import Network

@Observable
final class NetworkMonitor {
    var isConnected: Bool?
    var connectionType: NWInterface.InterfaceType?
    
    init() {
        startMonitoring()
    }
    
    /// - Monitor properties
    private var queue = DispatchQueue(label: "monitor_network")
    private var monitor = NWPathMonitor()
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                
                let types: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet, .loopback]
                if let type = types.first(where: { path.usesInterfaceType($0) }) {
                    self.connectionType = type
                } else {
                    self.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
}

