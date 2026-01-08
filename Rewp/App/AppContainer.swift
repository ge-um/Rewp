//
//  AppContainer.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation

final class AppContainer {
    // MARK: - Shared Dependencies

    lazy var networkService: NetworkServiceProtocol = {
        return NetworkService()
    }()

    lazy var authService: AuthServiceProtocol = {
        return AuthService(networkService: networkService, chatLocalStorage: chatLocalStorage)
    }()

    lazy var userRepository: UserRepository = {
        UserRepositoryImpl(networkService: networkService)
    }()

    lazy var logRepository: LogRepository = {
        LogRepositoryImpl(networkService: networkService)
    }()

    lazy var estateRepository: EstateRepository = {
        EstateRepositoryImpl(authService: authService)
    }()

    lazy var bannerRepository: BannerRepository = {
        BannerRepositoryImpl(authService: authService)
    }()

    lazy var paymentRepository: PaymentRepository = {
        PaymentRepositoryImpl(authService: authService)
    }()

    lazy var chatLocalStorage: ChatLocalStorage = {
        ChatLocalStorage()
    }()

    lazy var chatRepository: ChatRepository = {
        ChatRepositoryImpl(authService: authService, localStorage: chatLocalStorage)
    }()

    lazy var socketService: SocketServiceProtocol = {
        SocketService()
    }()

    lazy var notificationRepository: NotificationRepository = {
        NotificationRepositoryImpl(authService: authService as! AuthService)
    }()

    lazy var notificationManager: NotificationManager = {
        NotificationManager(
            notificationRepository: notificationRepository,
            authService: authService as! AuthService,
            container: self
        )
    }()

    lazy var unreadCountSyncService: UnreadCountSyncService = {
        UnreadCountSyncService(chatRepository: chatRepository, authService: authService)
    }()

    lazy var videoRepository: VideoRepository = {
        VideoRepositoryImpl(authService: authService)
    }()

    lazy var subtitleService: SubtitleService = {
        SubtitleService(videoRepository: videoRepository)
    }()

    // MARK: - Factory Methods

    func makeLoginViewController() -> LoginViewController {
        return LoginFactory.create(container: self)
    }

    func makeSignUpViewController() -> SignUpViewController {
        return SignUpFactory.create(container: self)
    }

    func makeFeedViewController() -> FeedViewController {
        return FeedFactory.create(container: self)
    }

    func makeSettingsViewController() -> SettingsViewController {
        return SettingsFactory.create(container: self)
    }

    func makeEstateDetailViewController(estateId: String) -> EstateDetailViewController {
        return EstateDetailFactory.create(estateId: estateId, container: self)
    }

    func makeChatRoomViewController(roomId: String, roomTitle: String) -> ChatRoomViewController {
        return ChatRoomFactory.create(roomId: roomId, roomTitle: roomTitle, container: self)
    }

    func makeChatRoomViewController(chatRoom: ChatRoom) -> ChatRoomViewController {
        return ChatRoomFactory.create(roomId: chatRoom.roomId, roomTitle: chatRoom.participantName, container: self)
    }

    func makeChatListViewController() -> ChatListViewController {
        return ChatListFactory.create(container: self)
    }

    func makeVideoListViewController() -> VideoListViewController {
        return VideoListFactory.create(container: self)
    }

    func makeAttendanceWebViewController(urlPath: String) -> AttendanceWebViewController {
        return AttendanceWebViewController(urlPath: urlPath, authService: authService)
    }

    func makeMapSearchViewController() -> MapSearchViewController {
        return MapSearchFactory.create(estateRepository: estateRepository)
    }
}
