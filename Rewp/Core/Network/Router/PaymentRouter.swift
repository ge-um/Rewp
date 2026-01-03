//
//  PaymentRouter.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation
import Alamofire

enum PaymentRouter {
    case createOrder(estateId: String, totalPrice: Int)
    case validatePayment(impUid: String)
}

extension PaymentRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .createOrder:
            return "/orders"
        case .validatePayment:
            return "/payments/validation"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createOrder, .validatePayment:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }

    var body: Encodable? {
        switch self {
        case .createOrder(let estateId, let totalPrice):
            return CreateOrderRequest(estate_id: estateId, total_price: totalPrice)
        case .validatePayment(let impUid):
            return ValidatePaymentRequest(imp_uid: impUid)
        }
    }
}
