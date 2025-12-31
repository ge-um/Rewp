//
//  GeocodeService.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import Foundation
import CoreLocation
import RxSwift

final class GeocodeService {
    static let shared = GeocodeService()

    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.rewp.geocode.cache")

    private init() {}

    func reverseGeocode(latitude: Double, longitude: Double) -> Single<String> {
        let cacheKey = "\(latitude),\(longitude)"

        if let cached = getCachedAddress(for: cacheKey) {
            return .just(cached)
        }

        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "GeocodeService", code: -1)))
                return Disposables.create()
            }

            let location = CLLocation(latitude: latitude, longitude: longitude)

            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    observer(.failure(error))
                    return
                }

                guard let placemark = placemarks?.first else {
                    observer(.failure(NSError(domain: "GeocodeService", code: -2, userInfo: [NSLocalizedDescriptionKey: "주소를 찾을 수 없습니다"])))
                    return
                }

                let address = self.formatAddress(from: placemark)
                self.setCachedAddress(address, for: cacheKey)
                observer(.success(address))
            }

            return Disposables.create {
                self.geocoder.cancelGeocode()
            }
        }
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        if let locality = placemark.locality {
            components.append(locality)
        }

        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        } else if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }

        return components.isEmpty ? "위치 정보 없음" : components.joined(separator: " ")
    }

    private func getCachedAddress(for key: String) -> String? {
        return cacheQueue.sync {
            return cache[key]
        }
    }

    private func setCachedAddress(_ address: String, for key: String) {
        cacheQueue.async { [weak self] in
            self?.cache[key] = address
        }
    }
}
