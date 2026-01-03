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
        return AuthService(networkService: networkService)
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

    lazy var paymentRepository: PaymentRepository = {
        PaymentRepositoryImpl(authService: authService)
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
}
