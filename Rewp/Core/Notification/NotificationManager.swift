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

    func getCurrentToken() -> String? {
        return fcmToken
    }

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

    /// 알림 탭 시 딥링킹 처리
    /// - Parameter userInfo: 알림 payload
    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        guard let roomId = userInfo["room_id"] as? String else {
            Logger.notification.error("Missing room_id in notification payload")
            return
        }

        guard let chatRepository = container?.chatRepository else {
            Logger.notification.error("ChatRepository not available")
            return
        }

        guard let currentUserId = authService.currentUserId else {
            Logger.notification.error("Not authenticated")
            return
        }

        chatRepository.fetchChatRoomsFromLocal()
            .take(1)
            .map { rooms in
                rooms.first(where: { $0.roomId == roomId })
            }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .flatMap { owner, cachedRoom -> Observable<ChatRoom?> in
                if let cachedRoom = cachedRoom {
                    return .just(cachedRoom)
                } else {
                    return chatRepository.getChatRooms()
                        .asObservable()
                        .map { response in
                            response.data.compactMap { $0.toDomain(currentUserId: currentUserId) }
                        }
                        .map { rooms in
                            rooms.first(where: { $0.roomId == roomId })
                        }
                }
            }
            .withUnretained(self)
            .subscribe(
                onNext: { owner, chatRoom in
                    if let chatRoom = chatRoom {
                        owner.navigateToChatRoom(chatRoom)
                    } else {
                        Logger.notification.error("Chat room not found - \(roomId, privacy: .public)")
                        owner.navigateToChatList()
                    }
                },
                onError: { error in
                    Logger.notification.error("Failed to fetch chat room - \(error.localizedDescription)")
                    self.navigateToChatList()
                }
            )
            .disposed(by: disposeBag)
    }

    /// 활성 UIWindow 반환
    /// - Returns: 현재 활성화된 키 윈도우
    private func getKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }

    private func navigateToChatRoom(_ chatRoom: ChatRoom) {
        guard let window = getKeyWindow() else {
            Logger.notification.error("Navigation failed - window unavailable")
            return
        }

        guard let nav = window.rootViewController as? UINavigationController,
              let mainTab = nav.viewControllers.first as? MainTabBarController else {
            Logger.notification.error("Navigation failed - MainTabBarController not found")
            return
        }

        mainTab.navigateToChatRoom(chatRoom: chatRoom)
    }

    /// 채팅방 목록으로 네비게이션 (fallback)
    private func navigateToChatList() {
        guard let window = getKeyWindow() else {
            Logger.notification.error("Navigation failed - window unavailable")
            return
        }

        if let nav = window.rootViewController as? UINavigationController,
           let mainTab = nav.viewControllers.first as? MainTabBarController {
            mainTab.selectTab(at: 2)
        } else {
            Logger.notification.error("Navigation failed - MainTabBarController not found")
        }
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
        handleNotificationTap(response.notification.request.content.userInfo)
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
