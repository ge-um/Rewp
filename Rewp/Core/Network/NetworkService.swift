//
//  NetworkService.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation
import Alamofire
import RxSwift

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ router: APIRouter) -> Single<T>
    func requestEmpty(_ router: APIRouter) -> Single<Void>
}

final class NetworkService: NetworkServiceProtocol {
    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func request<T: Decodable>(_ router: APIRouter) -> Single<T> {
        return Single.create { observer in
            let dataRequest = self.session.request(router)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        observer(.success(value))
                    case .failure:
                        if let data = response.data,
                           let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                        } else {
                            observer(.failure(NetworkError.decodingError))
                        }
                    }
                }

            return Disposables.create {
                dataRequest.cancel()
            }
        }
    }

    func requestEmpty(_ router: APIRouter) -> Single<Void> {
        return Single.create { observer in
            let dataRequest = self.session.request(router)
                .validate(statusCode: 200..<300)
                .response { response in
                    switch response.result {
                    case .success:
                        observer(.success(()))
                    case .failure:
                        if let data = response.data,
                           let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                        } else {
                            observer(.failure(NetworkError.serverError(message: "서버 오류가 발생했습니다.")))
                        }
                    }
                }

            return Disposables.create {
                dataRequest.cancel()
            }
        }
    }

}
