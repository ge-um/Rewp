//
//  EstateDetailPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class EstateDetailPresenter {
    private let estateId: String
    private let repository: EstateRepository
    private let paymentRepository: PaymentRepository
    private let chatRepository: ChatRepository
    private let disposeBag = DisposeBag()

    init(estateId: String, repository: EstateRepository, paymentRepository: PaymentRepository, chatRepository: ChatRepository) {
        self.estateId = estateId
        self.repository = repository
        self.paymentRepository = paymentRepository
        self.chatRepository = chatRepository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let similarEstateTapped: Observable<String>
        let likeTapped: Observable<Void>
        let reservationTapped: Observable<Void>
        let chatTapped: Observable<Void>
    }

    struct Output {
        let estateDetail: Driver<EstateDetail>
        let similarEstates: Driver<[SimilarEstateItem]>
        let navigateToDetail: Driver<String>
        let error: Driver<String>
        let isLoading: Driver<Bool>
        let likeStatus: Driver<Bool>
        let orderCreated: Driver<CreateOrderResponse>
        let reservationCompleted: Driver<Void>
        let chatRoomCreated: Driver<(roomId: String, roomTitle: String)>
    }

    func transform(input: Input) -> Output {
        let errorRelay = PublishRelay<String>()
        let loadingRelay = PublishRelay<Bool>()
        let likeStatusRelay = BehaviorRelay<Bool>(value: false)
        let orderCreatedRelay = PublishRelay<CreateOrderResponse>()
        let estateDetailRelay = BehaviorRelay<EstateDetail?>(value: nil)
        let reservationCompletedRelay = PublishRelay<Void>()
        let chatRoomCreatedRelay = PublishRelay<(roomId: String, roomTitle: String)>()

        let estateDetail = input.viewDidLoad
            .do(onNext: {
                loadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<EstateDetail> in
                guard let self = self else {
                    Logger.ui.error("Self is nil in flatMapLatest")
                    return .empty()
                }
                return self.repository.fetchEstateDetail(estateId: self.estateId)
                    .map { response in
                        response.toEstateDetail()
                    }
                    .asObservable()
                    .do(onNext: { detail in
                        loadingRelay.accept(false)
                        likeStatusRelay.accept(detail.isLiked)
                        estateDetailRelay.accept(detail)
                    })
                    .catch { error in
                        Logger.ui.error("fetchEstateDetail error: \(error.localizedDescription)")
                        loadingRelay.accept(false)
                        errorRelay.accept(error.localizedDescription)
                        return .empty()
                    }
            }
            .asDriver(onErrorDriveWith: .empty())

        let similarEstates = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[SimilarEstateItem]> in
                guard let self = self else { return .empty() }
                return self.repository.fetchSimilarEstates()
                    .map { estateList in
                        estateList.map { $0.toSimilarEstateItem() }
                    }
                    .asObservable()
                    .catch { error in
                        Logger.ui.error("fetchSimilarEstates error: \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])

        let navigateToDetail = input.similarEstateTapped
            .asDriver(onErrorDriveWith: .empty())

        input.likeTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let currentStatus = likeStatusRelay.value
                let newStatus = !currentStatus
                likeStatusRelay.accept(newStatus)

                owner.repository.likeEstate(estateId: owner.estateId, likeStatus: newStatus)
                    .subscribe(onSuccess: { _ in
                        Logger.ui.notice("Like status updated - estateId: \(owner.estateId), status: \(newStatus)")
                    }, onFailure: { error in
                        Logger.ui.error("Like estate failed - \(error.localizedDescription)")
                        likeStatusRelay.accept(currentStatus)
                        errorRelay.accept("좋아요 처리에 실패했습니다.")
                    })
                    .disposed(by: owner.disposeBag)
            })
            .disposed(by: disposeBag)

        input.reservationTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                guard let detail = estateDetailRelay.value else {
                    errorRelay.accept("매물 정보를 불러오는 중입니다.")
                    return
                }

                if detail.isReserved {
                    errorRelay.accept("이미 예약된 매물입니다.")
                    return
                }

                loadingRelay.accept(true)

                owner.paymentRepository.createOrder(estateId: owner.estateId, totalPrice: detail.reservationPrice)
                    .subscribe(onSuccess: { orderResponse in
                        loadingRelay.accept(false)
                        Logger.ui.notice("Order created - order_code: \(orderResponse.order_code)")
                        orderCreatedRelay.accept(orderResponse)
                    }, onFailure: { error in
                        loadingRelay.accept(false)
                        Logger.ui.error("Create order failed - \(error.localizedDescription)")

                        if error.localizedDescription.contains("이미 예약된 매물입니다") {
                            reservationCompletedRelay.accept(())
                        } else {
                            errorRelay.accept(error.localizedDescription)
                        }
                    })
                    .disposed(by: owner.disposeBag)
            })
            .disposed(by: disposeBag)

        input.chatTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                guard let detail = estateDetailRelay.value else {
                    errorRelay.accept("매물 정보를 불러오는 중입니다.")
                    return
                }

                loadingRelay.accept(true)

                owner.chatRepository.createChatRoom(opponentId: detail.creatorId)
                    .subscribe(onSuccess: { response in
                        loadingRelay.accept(false)
                        Logger.socket.notice("Chat room created - room_id: \(response.room_id, privacy: .public)")
                        chatRoomCreatedRelay.accept((roomId: response.room_id, roomTitle: detail.creatorName))
                    }, onFailure: { error in
                        loadingRelay.accept(false)
                        Logger.socket.error("Create chat room failed - \(error.localizedDescription)")
                        errorRelay.accept("채팅방 생성에 실패했습니다.")
                    })
                    .disposed(by: owner.disposeBag)
            })
            .disposed(by: disposeBag)

        return Output(
            estateDetail: estateDetail,
            similarEstates: similarEstates,
            navigateToDetail: navigateToDetail,
            error: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다."),
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            likeStatus: likeStatusRelay.asDriver(),
            orderCreated: orderCreatedRelay.asDriver(onErrorDriveWith: .empty()),
            reservationCompleted: reservationCompletedRelay.asDriver(onErrorDriveWith: .empty()),
            chatRoomCreated: chatRoomCreatedRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
