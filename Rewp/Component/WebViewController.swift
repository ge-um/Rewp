//
//  WebViewController.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import UIKit
import WebKit
import PinLayout
import Then

final class WebViewController: UIViewController {
    private let webView = WKWebView()
    private let url: URL
    private var navigationBar: CustomNavigationBar!

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        loadURL()
    }

    private func setupUI() {
        navigationBar = addCustomNavigationBar(title: "부동산 TOPIC", showBackButton: true)
        enableSwipeBackGesture()

        view.addSubview(webView)
    }

    private func loadURL() {
        let request = URLRequest(url: url)
        webView.load(request)
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
}
