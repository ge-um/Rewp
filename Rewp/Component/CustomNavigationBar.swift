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
    private let backgroundView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

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
            titleLabel.typography(FontSystem.Pretendard.body1Bold, text: title)
        }
        backButton.isHidden = !showBackButton
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(backgroundView)
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(rightButton)
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        onBackButtonTap?()
    }

    func setTitle(_ title: String) {
        titleLabel.typography(FontSystem.Pretendard.body1Bold, text: title)
        setNeedsLayout()
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        let safeAreaTop = superview?.safeAreaInsets.top ?? 0
        backgroundView.pin
            .top(-safeAreaTop)
            .horizontally()
            .bottom()

        backButton.pin
            .left(12)
            .vCenter()
            .size(32)

        titleLabel.pin
            .after(of: backButton)
            .marginLeft(8)
            .right()
            .vCenter()
            .sizeToFit(.width)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 56)
    }
}

extension UIViewController {
    func addCustomNavigationBar(title: String? = nil) -> CustomNavigationBar {
        let navBar = CustomNavigationBar(title: title)
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
