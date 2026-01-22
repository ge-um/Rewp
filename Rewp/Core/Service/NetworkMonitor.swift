//
//  NetworkMonitor.swift
//  Rewp
//
//  Created by 금가경 on 01/18/26.
//

import Foundation
import Network
import RxSwift
import RxCocoa
import OSLog

protocol NetworkMonitorProtocol {
    var isConnected: Observable<Bool> { get }
    var currentStatus: Bool { get }
    func startMonitoring()
    func stopMonitoring()
}

final class NetworkMonitor: NetworkMonitorProtocol {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.rewp.networkmonitor")
    private let isConnectedRelay = BehaviorRelay<Bool>(value: true)

    var isConnected: Observable<Bool> {
        return isConnectedRelay
            .asObservable()
            .distinctUntilChanged()
    }

    var currentStatus: Bool {
        return isConnectedRelay.value
    }

    private init() {}

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.isConnectedRelay.accept(isConnected)

            if isConnected {
                Logger.network.notice("Network connected")
            } else {
                Logger.network.notice("Network disconnected")
            }
        }
        monitor.start(queue: queue)
        Logger.network.notice("Network monitoring started")
    }

    func stopMonitoring() {
        monitor.cancel()
        Logger.network.notice("Network monitoring stopped")
    }
}
