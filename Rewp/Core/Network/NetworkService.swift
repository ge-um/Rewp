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
                .responseDecodable(of: T.self) { response in
                    if let statusCode = response.response?.statusCode {
                        if (200...299).contains(statusCode) {
                            switch response.result {
                            case .success(let value):
                                observer(.success(value))
                            case .failure:
                                observer(.failure(NetworkError.decodingError))
                            }
                        } else if statusCode == 419 {
                            observer(.failure(AuthError.tokenExpired))
                        } else if statusCode == 401 || statusCode == 403 {
                            observer(.failure(AuthError.notAuthenticated))
                        } else {
                            if let data = response.data,
                               let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                            } else {
                                observer(.failure(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다.")))
                            }
                        }
                    } else {
                        observer(.failure(NetworkError.serverError(message: "서버 응답을 받지 못했습니다.")))
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
                .response { response in
                    if let statusCode = response.response?.statusCode {
                        if (200...299).contains(statusCode) {
                            observer(.success(()))
                        } else if statusCode == 419 {
                            observer(.failure(AuthError.tokenExpired))
                        } else if statusCode == 401 || statusCode == 403 {
                            observer(.failure(AuthError.notAuthenticated))
                        } else {
                            if let data = response.data,
                               let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                            } else {
                                observer(.failure(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다.")))
                            }
                        }
                    } else {
                        observer(.failure(NetworkError.serverError(message: "서버 응답을 받지 못했습니다.")))
                    }
                }

            return Disposables.create {
                dataRequest.cancel()
            }
        }
    }

}
