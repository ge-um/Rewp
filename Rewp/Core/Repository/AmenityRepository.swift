//
//  AmenityRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation
import RxSwift
import Alamofire

protocol AmenityRepository {
    func searchPlaces(keyword: String, longitude: Double, latitude: Double, radius: Int, size: Int) -> Single<KakaoPlaceResponse>
}

final class AmenityRepositoryImpl: AmenityRepository {
    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func searchPlaces(keyword: String, longitude: Double, latitude: Double, radius: Int, size: Int) -> Single<KakaoPlaceResponse> {
        return Single.create { single in
            let request = self.session.request(
                KakaoRouter.searchKeyword(
                    query: keyword,
                    x: String(longitude),
                    y: String(latitude),
                    radius: radius,
                    size: size
                )
            )
            .validate()
            .responseDecodable(of: KakaoPlaceResponse.self) { response in
                switch response.result {
                case .success(let data):
                    single(.success(data))
                case .failure(let error):
                    single(.failure(error))
                }
            }

            return Disposables.create {
                request.cancel()
            }
        }
    }
}
