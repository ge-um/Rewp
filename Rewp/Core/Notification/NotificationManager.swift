//
//  NotificationManager.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import UIKit
import RxSwift
import FirebaseMessaging
import UserNotifications
import OSLog

final class NotificationManager: NSObject {
    private let notificationRepository: NotificationRepository
    private let authService: AuthService
    private weak var container: AppContainer?
    private let disposeBag = DisposeBag()

    private var fcmToken: String?

    init(
        notificationRepository: NotificationRepository,
        authService: AuthService,
        container: AppContainer
    ) {
        self.notificationRepository = notificationRepository
        self.authService = authService
        self.container = container
        super.init()
    }

    /// 알림 권한 요청
    /// - Returns: 권한 허용 여부
    func requestPermission() -> Observable<Bool> {
        return Observable.create { observer in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    Logger.notification.error("Permission request failed - \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    Logger.notification.notice("Permission granted: \(granted)")
                    observer.onNext(granted)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    /// 현재 FCM 토큰 반환 (로그인 API용)
    /// - Returns: FCM 토큰 (없으면 nil)
    func getCurrentToken() -> String? {
        return fcmToken
    }

    /// 디바이스 토큰을 서버에 전송 (로그인 상태일 때만)
    /// - Returns: 성공 시 Void, 실패 시 에러
    func updateDeviceToken() -> Single<Void> {
        guard authService.isAuthenticated() else {
            Logger.fcm.debug("Not authenticated - skipping token update")
            return .just(())
        }

        guard let token = fcmToken else {
            Logger.fcm.debug("No FCM token available")
            return .just(())
        }

        return notificationRepository.updateDeviceToken(token)
            .do(
                onSuccess: {
                    Logger.fcm.notice("Device token updated")
                },
                onError: { error in
                    Logger.fcm.error("Token update failed - \(error.localizedDescription)")
                }
            )
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    /// 포그라운드 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Logger.notification.debug("Notification received in foreground")
        completionHandler([.banner, .sound, .badge])
    }

    /// 알림 탭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Logger.notification.notice("Notification tapped")
        // TODO: 딥링킹 구현 (2단계)
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    /// FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }

        Logger.fcm.debug("FCM token received")
        self.fcmToken = fcmToken

        // 로그인 상태일 때만 서버 전송
        updateDeviceToken()
            .subscribe()
            .disposed(by: disposeBag)
    }
}
