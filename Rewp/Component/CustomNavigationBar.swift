//
//  CustomNavigationBar.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout
import Then

final class CustomNavigationBar: UIView {
    private let backButton = UIButton(type: .system).then {
        let image = UIImage(named: "chevron")
        $0.setImage(image, for: .normal)
        $0.tintColor = ColorSystem.gray75
        $0.contentMode = .center
    }

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body1, text: "")
        $0.textColor = ColorSystem.gray90
        $0.textAlignment = .center
    }

    var onBackButtonTap: (() -> Void)?

    init(title: String? = nil, showBackButton: Bool = true) {
        super.init(frame: .zero)
        backgroundColor = ColorSystem.gray0
        titleLabel.text = title
        backButton.isHidden = !showBackButton
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(backButton)
        addSubview(titleLabel)
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        onBackButtonTap?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backButton.pin
            .left(16)
            .vCenter()
            .size(44)

        titleLabel.pin
            .horizontally(60)
            .vCenter()
            .sizeToFit(.width)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 56)
    }
}

extension UIViewController {
    func addCustomNavigationBar(title: String? = nil, showBackButton: Bool = true) -> CustomNavigationBar {
        let navBar = CustomNavigationBar(title: title, showBackButton: showBackButton)
        view.addSubview(navBar)

        navBar.onBackButtonTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        return navBar
    }

    func enableSwipeBackGesture() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
}
