//
//  GeocodeService.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import Foundation
import CoreLocation
import MapKit
import RxSwift

final class GeocodeService {
    static let shared = GeocodeService()

    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.rewp.geocode.cache")
    private let networkManager = NetworkService()

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

    func reverseGeocodeForLocationTitle(latitude: Double, longitude: Double) -> Single<String> {
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

                let locationTitle = self.formatLocationTitle(from: placemark)
                observer(.success(locationTitle))
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

    private func formatLocationTitle(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        } else if let subLocality = placemark.subLocality {
            components.append(subLocality)
        } else if let name = placemark.name {
            components.append(name)
        }

        if let subLocality = placemark.subLocality, placemark.thoroughfare != nil {
            components.append(subLocality)
        }

        return components.isEmpty ? "위치 확인 중..." : components.joined(separator: ", ")
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

    func forwardGeocode(address: String) -> Single<CLLocationCoordinate2D> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "GeocodeService", code: -1)))
                return Disposables.create()
            }

            self.geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    observer(.failure(error))
                    return
                }

                guard let location = placemarks?.first?.location else {
                    observer(.failure(NSError(
                        domain: "GeocodeService",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "좌표를 찾을 수 없습니다"]
                    )))
                    return
                }

                observer(.success(location.coordinate))
            }

            return Disposables.create {
                self.geocoder.cancelGeocode()
            }
        }
    }

    func searchLocations(query: String) -> Single<[(address: String, coordinate: CLLocationCoordinate2D, type: LocationType)]> {
        return networkManager.request(
            KakaoRouter.searchKeyword(
                query: query,
                x: nil,
                y: nil,
                radius: nil,
                size: 15
            )
        )
        .map { (response: KakaoSearchResponse) -> [(address: String, coordinate: CLLocationCoordinate2D, type: LocationType)] in
            guard !response.documents.isEmpty else {
                throw NSError(
                    domain: "GeocodeService",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "검색 결과가 없습니다"]
                )
            }

            let results = response.documents.compactMap { place -> (address: String, coordinate: CLLocationCoordinate2D, type: LocationType)? in
                guard let latitude = Double(place.y),
                      let longitude = Double(place.x) else {
                    return nil
                }

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let formattedAddress = self.formatAddressWithoutBeonji(place.addressName)

                let isSubway = place.categoryName.contains("지하철") || place.categoryName.contains("전철")
                let isUniversity = place.categoryName.contains("대학교")

                if isSubway {
                    return (address: place.placeName, coordinate: coordinate, type: .subway)
                } else if isUniversity {
                    return (address: place.placeName, coordinate: coordinate, type: .university)
                } else {
                    return (address: formattedAddress, coordinate: coordinate, type: .address)
                }
            }

            guard !results.isEmpty else {
                throw NSError(
                    domain: "GeocodeService",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "검색 결과가 없습니다"]
                )
            }

            return results
        }
    }

    private func formatAddressWithoutBeonji(_ address: String) -> String {
        let components = address.split(separator: " ").map(String.init)

        guard !components.isEmpty else {
            return address
        }

        var result: [String] = []

        for component in components {
            if component.first?.isNumber == true {
                break
            }

            if component.contains(where: { $0.isNumber }) && (component.contains("-") || component.allSatisfy { $0.isNumber || $0 == "-" }) {
                break
            }

            result.append(component)
        }

        return result.isEmpty ? address : result.joined(separator: " ")
    }
}
