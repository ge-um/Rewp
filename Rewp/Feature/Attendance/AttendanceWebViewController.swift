//
//  AttendanceWebViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import UIKit
import WebKit
import PinLayout
import OSLog

final class AttendanceWebViewController: UIViewController, WKScriptMessageHandler {
    private var webView: WKWebView!
    private let urlPath: String
    private let authService: AuthServiceProtocol
    private var navigationBar: CustomNavigationBar!

    init(urlPath: String, authService: AuthServiceProtocol) {
        self.urlPath = urlPath
        self.authService = authService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupWebView()
        setupUI()
        loadURL()
    }

    private func setupWebView() {
        let controller = WKUserContentController()
        controller.add(self, name: "click_attendance_button")
        controller.add(self, name: "complete_attendance")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = WKWebView(frame: .zero, configuration: config)
    }

    private func setupUI() {
        navigationBar = addCustomNavigationBar(title: "출석 이벤트")
        enableSwipeBackGesture()
        view.addSubview(webView)
    }

    private func loadURL() {
        let baseURL = NetworkConfig.baseURL.replacingOccurrences(of: "/v1", with: "")
        guard let url = URL(string: "\(baseURL)\(urlPath)") else { return }

        var request = URLRequest(url: url)
        request.setValue(NetworkConfig.rewpKey, forHTTPHeaderField: "SesacKey")
        webView.load(request)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "click_attendance_button":
            guard let accessToken = try? KeychainManager.shared.loadAccessToken() else {
                Logger.auth.error("Failed to load access token for attendance")
                return
            }
            webView.evaluateJavaScript("requestAttendance('\(accessToken)')")

        case "complete_attendance":
            if let attendanceCount = message.body as? Int {
                showAttendanceCompleteAlert(count: attendanceCount)
            }

        default:
            break
        }
    }

    private func showAttendanceCompleteAlert(count: Int) {
        let alert = UIAlertController(
            title: "출석 완료",
            message: "\(count)번째 출석 완료!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                guard let self = self, self.presentedViewController == alert else { return }
                alert.dismiss(animated: true) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        webView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "click_attendance_button")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "complete_attendance")
    }
}
