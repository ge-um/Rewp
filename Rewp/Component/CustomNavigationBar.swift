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
        $0.textColor = ColorSystem.gray90
        $0.textAlignment = .left
    }

    private let rightButton = UIButton().then {
        $0.setImage(UIImage(named: "Like_Empty")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = ColorSystem.gray60
    }

    var onBackButtonTap: (() -> Void)?
    var onRightButtonTapped: (() -> Void)?

    init(title: String? = nil, showBackButton: Bool = true, showRightButton: Bool = false) {
        super.init(frame: .zero)
        if let title = title {
            titleLabel.typography(FontSystem.Pretendard.body1, text: title)
        }
        backButton.isHidden = !showBackButton
        rightButton.isHidden = !showRightButton
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(rightButton)
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        onBackButtonTap?()
    }

    @objc private func rightButtonTapped() {
        onRightButtonTapped?()
    }

    func setTitle(_ title: String) {
        titleLabel.typography(FontSystem.Pretendard.body1, text: title)
        setNeedsLayout()
    }

    func setRightButtonImage(filled: Bool = false) {
        let imageName = filled ? "Like_Fill" : "Like_Empty"
        rightButton.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backButton.pin
            .left(16)
            .vCenter()
            .size(44)

        rightButton.pin
            .right(20)
            .vCenter()
            .size(24)

        titleLabel.pin
            .after(of: backButton)
            .marginLeft(8)
            .before(of: rightButton)
            .marginRight(8)
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
