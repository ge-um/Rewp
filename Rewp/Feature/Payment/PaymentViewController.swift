//
//  PaymentViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import WebKit
import iamport_ios
import OSLog
import PinLayout
import Then

final class PaymentViewController: UIViewController {
    private let webView = WKWebView()
    private let orderResponse: CreateOrderResponse
    private let estateTitle: String
    var onPaymentComplete: ((String) -> Void)?
    var onPaymentFailed: ((String) -> Void)?

    init(orderResponse: CreateOrderResponse, estateTitle: String) {
        self.orderResponse = orderResponse
        self.estateTitle = estateTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupWebView()
        initiatePayment()
    }

    private func setupWebView() {
        view.addSubview(webView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.pin.all(view.pin.safeArea)
    }

    private func initiatePayment() {
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: orderResponse.order_code,
            amount: "\(orderResponse.total_price)"
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = estateTitle
            $0.buyer_name = "금가경"
            $0.app_scheme = "rewp"
        }

        Iamport.shared.paymentWebView(
            webViewMode: webView,
            userCode: NetworkConfig.iamportUserCode,
            payment: payment
        ) { [weak self] iamportResponse in
            guard let self = self else { return }

            if let success = iamportResponse?.success, success {
                if let impUid = iamportResponse?.imp_uid {
                    Logger.ui.notice("Payment succeeded - imp_uid: \(impUid)")
                    self.dismiss(animated: true) {
                        self.onPaymentComplete?(impUid)
                    }
                }
            } else {
                let errorMessage = iamportResponse?.error_msg ?? "결제에 실패했습니다."
                Logger.ui.error("Payment failed - \(errorMessage)")
                self.dismiss(animated: true) {
                    self.onPaymentFailed?(errorMessage)
                }
            }
        }
    }
}
