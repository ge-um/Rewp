//
//  PaymentRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation
import RxSwift
import OSLog

protocol PaymentRepository {
    func createOrder(estateId: String, totalPrice: Int) -> Single<CreateOrderResponse>
    func validatePayment(impUid: String) -> Single<ValidatePaymentResponse>
}

final class PaymentRepositoryImpl: PaymentRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func createOrder(estateId: String, totalPrice: Int) -> Single<CreateOrderResponse> {
        return authService.authenticatedRequest(PaymentRouter.createOrder(estateId: estateId, totalPrice: totalPrice))
    }

    func validatePayment(impUid: String) -> Single<ValidatePaymentResponse> {
        return authService.authenticatedRequest(PaymentRouter.validatePayment(impUid: impUid))
            .do(onSuccess: { response in
                Logger.ui.notice("Payment validation response received")
            }, onError: { error in
                Logger.ui.error("Payment validation decode error: \(error)")
            })
    }
}
