//
//  NotificationRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import RxSwift

/// FCM 디바이스 토큰을 서버에 전송하는 Repository
protocol NotificationRepository {
    /// 디바이스 토큰을 서버에 업데이트
    /// - Parameter token: FCM 토큰
    /// - Returns: 성공 시 Void, 실패 시 에러
    func updateDeviceToken(_ token: String) -> Single<Void>
}

final class NotificationRepositoryImpl: NotificationRepository {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func updateDeviceToken(_ token: String) -> Single<Void> {
        let request = DeviceTokenRequest(deviceToken: token)

        return authService.authenticatedRequestEmpty(
            UserRouter.updateDeviceToken(request)
        )
    }
}
