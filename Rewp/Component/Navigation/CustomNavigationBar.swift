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
import FlexLayout
import Then

final class CustomNavigationBar: UIView {
    private let backgroundView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let contentContainer = UIView()
    private let navigationContainer = UIView()

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

    private let locationIconView = UIImageView().then {
        $0.image = UIImage(named: "Location")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.gray90
        $0.contentMode = .scaleAspectFit
    }

    private let locationTitleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
        $0.textAlignment = .left
    }

    private let rightButton = UIButton().then {
        $0.setImage(UIImage(named: "Like_Empty")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = ColorSystem.gray60
    }

    private var searchBar: SearchBar?

    private var useLocationTitle: Bool = false

    var onBackButtonTap: (() -> Void)?
    var onRightButtonTapped: (() -> Void)?
    var onSearchBarTap: (() -> Void)?

    private var showBackButton: Bool = true

    init(title: String? = nil, showBackButton: Bool = true, showRightButton: Bool = false, showSearchBar: Bool = false, useLocationTitle: Bool = false) {
        super.init(frame: .zero)
        self.useLocationTitle = useLocationTitle
        self.showBackButton = showBackButton

        if useLocationTitle {
            locationTitleLabel.typography(FontSystem.Pretendard.body1Bold, text: title ?? "위치 확인 중...")
        } else if let title = title {
            titleLabel.typography(FontSystem.Pretendard.body1Bold, text: title)
        }

        if showSearchBar {
            let searchBar = SearchBar()
            self.searchBar = searchBar
            searchBar.onTap = { [weak self] in
                self?.onSearchBarTap?()
            }
        }

        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(backgroundView)
        addSubview(contentContainer)

        contentContainer.flex
            .direction(.column)
            .define { flex in
                flex.addItem(navigationContainer)
                    .direction(.row)
                    .alignItems(.center)
                    .height(56)
                    .paddingHorizontal(12)
                    .define { navFlex in
                        if showBackButton {
                            navFlex.addItem(backButton)
                                .size(32)
                                .marginRight(8)
                        }

                        if useLocationTitle {
                            navFlex.addItem(locationIconView)
                                .size(24)
                                .marginRight(4)

                            navFlex.addItem(locationTitleLabel)
                                .grow(1)
                        } else {
                            navFlex.addItem(titleLabel)
                                .grow(1)
                        }
                    }

                if let searchBar = searchBar {
                    flex.addItem(searchBar)
                        .marginHorizontal(20)
                        .height(40)
                }
            }
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

    func updateLocationTitle(_ location: String) {
        guard useLocationTitle else { return }
        locationTitleLabel.typography(FontSystem.Pretendard.body1Bold, text: location)
        contentContainer.flex.layout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let safeAreaTop = superview?.safeAreaInsets.top ?? 0
        backgroundView.pin
            .top(-safeAreaTop)
            .horizontally()
            .bottom()

        contentContainer.pin
            .all()

        contentContainer.flex.layout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if searchBar != nil {
            return CGSize(width: size.width, height: 112)
        } else {
            return CGSize(width: size.width, height: 56)
        }
    }
}

extension UIViewController {
    func addCustomNavigationBar(title: String? = nil, showSearchBar: Bool = false, useLocationTitle: Bool = false) -> CustomNavigationBar {
        let navBar = CustomNavigationBar(title: title, showSearchBar: showSearchBar, useLocationTitle: useLocationTitle)
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
