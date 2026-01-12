//
//  AmenitySearchService.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation
import RxSwift
import OSLog

enum AmenityCategory {
    case parks
    case mountains
    case rivers
    case veterinary
    case cafes
    case playgrounds

    var keyword: String {
        switch self {
        case .parks:
            return "공원"
        case .mountains:
            return "산"
        case .rivers:
            return "강"
        case .veterinary:
            return "동물병원"
        case .cafes:
            return "애견동반카페"
        case .playgrounds:
            return "애견운동장"
        }
    }
}

final class AmenitySearchService {
    static let shared = AmenitySearchService()

    private let repository: AmenityRepository
    private let disposeBag = DisposeBag()
    private var cache: [String: (amenityInfo: AmenityInfo, timestamp: Date)] = [:]
    private let cacheExpirationInterval: TimeInterval = 600

    private init(repository: AmenityRepository = AmenityRepositoryImpl()) {
        self.repository = repository
    }

    func searchAmenities(latitude: Double, longitude: Double, radius: Int) -> Single<AmenityInfo> {
        let cacheKey = "\(latitude)_\(longitude)_\(radius)"

        if let cached = cache[cacheKey], Date().timeIntervalSince(cached.timestamp) < cacheExpirationInterval {
            return .just(cached.amenityInfo)
        }

        let parkSearch = repository.searchPlaces(keyword: AmenityCategory.parks.keyword, longitude: longitude, latitude: latitude, radius: radius, size: 15)
        let mountainSearch = repository.searchPlaces(keyword: AmenityCategory.mountains.keyword, longitude: longitude, latitude: latitude, radius: radius, size: 15)
        let riverSearch = repository.searchPlaces(keyword: AmenityCategory.rivers.keyword, longitude: longitude, latitude: latitude, radius: radius, size: 15)
        let veterinarySearch = repository.searchPlaces(keyword: AmenityCategory.veterinary.keyword, longitude: longitude, latitude: latitude, radius: radius, size: 15)
        let cafeSearch = repository.searchPlaces(keyword: AmenityCategory.cafes.keyword, longitude: longitude, latitude: latitude, radius: radius, size: 15)
        let playgroundSearch = repository.searchPlaces(keyword: AmenityCategory.playgrounds.keyword, longitude: longitude, latitude: latitude, radius: radius, size: 15)

        return Single.zip(
            parkSearch.catch { _ in .just(KakaoPlaceResponse(meta: .init(total_count: 0, pageable_count: 0, is_end: true), documents: [])) },
            mountainSearch.catch { _ in .just(KakaoPlaceResponse(meta: .init(total_count: 0, pageable_count: 0, is_end: true), documents: [])) },
            riverSearch.catch { _ in .just(KakaoPlaceResponse(meta: .init(total_count: 0, pageable_count: 0, is_end: true), documents: [])) },
            veterinarySearch.catch { _ in .just(KakaoPlaceResponse(meta: .init(total_count: 0, pageable_count: 0, is_end: true), documents: [])) },
            cafeSearch.catch { _ in .just(KakaoPlaceResponse(meta: .init(total_count: 0, pageable_count: 0, is_end: true), documents: [])) },
            playgroundSearch.catch { _ in .just(KakaoPlaceResponse(meta: .init(total_count: 0, pageable_count: 0, is_end: true), documents: [])) }
        )
        .map { [weak self] parkResponse, mountainResponse, riverResponse, veterinaryResponse, cafeResponse, playgroundResponse in
            var uniquePlaces: Set<String> = []
            var parkCount = 0
            var mountainCount = 0
            var riverCount = 0
            var veterinaryCount = 0
            var cafeCount = 0
            var playgroundCount = 0

            for document in parkResponse.documents {
                if uniquePlaces.insert(document.id).inserted {
                    parkCount += 1
                }
            }

            for document in mountainResponse.documents {
                if uniquePlaces.insert(document.id).inserted {
                    mountainCount += 1
                }
            }

            for document in riverResponse.documents {
                if uniquePlaces.insert(document.id).inserted {
                    riverCount += 1
                }
            }

            for document in veterinaryResponse.documents {
                if uniquePlaces.insert(document.id).inserted {
                    veterinaryCount += 1
                }
            }

            for document in cafeResponse.documents {
                if uniquePlaces.insert(document.id).inserted {
                    cafeCount += 1
                }
            }

            for document in playgroundResponse.documents {
                if uniquePlaces.insert(document.id).inserted {
                    playgroundCount += 1
                }
            }

            let amenityInfo = AmenityInfo(
                parks: parkCount,
                mountains: mountainCount,
                rivers: riverCount,
                veterinary: veterinaryCount,
                cafes: cafeCount,
                playgrounds: playgroundCount
            )

            self?.cache[cacheKey] = (amenityInfo: amenityInfo, timestamp: Date())
            return amenityInfo
        }
        .catch { _ in
            return .just(AmenityInfo(parks: 0, mountains: 0, rivers: 0, veterinary: 0, cafes: 0, playgrounds: 0))
        }
    }
}
