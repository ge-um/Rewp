//
//  TabBar.swift
//  Rewp
//
//  Created by 금가경 on 12/17/25.
//

import UIKit
import PinLayout
import Then
import RxSwift
import RxCocoa

enum TabBarItem: Int, CaseIterable {
    case home
    case favorites
    case settings

    var title: String {
        switch self {
        case .home: return "홈"
        case .favorites: return "관심매물"
        case .settings: return "설정"
        }
    }

    var emptyIcon: UIImage? {
        switch self {
        case .home: return UIImage(named: "Home_Empty")
        case .favorites: return UIImage(named: "Interest_Empty")
        case .settings: return UIImage(named: "Setting_Empty")
        }
    }

    var fillIcon: UIImage? {
        switch self {
        case .home: return UIImage(named: "Home_Fill")
        case .favorites: return UIImage(named: "Interest_Fill")
        case .settings: return UIImage(named: "Setting_Fill")
        }
    }
}

final class TabBar: UIView {
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.alignment = .fill
    }

    private var tabButtons: [TabBarButton] = []

    let selectedIndexRelay = BehaviorRelay<Int>(value: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.gray0

        layer.shadowColor = ColorSystem.gray100.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 1

        addSubview(stackView)

        TabBarItem.allCases.forEach { item in
            let button = TabBarButton(item: item)
            button.tag = item.rawValue
            button.addTarget(self, action: #selector(didTapTab(_:)), for: .touchUpInside)
            tabButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        selectTab(at: 0)
    }

    @objc private func didTapTab(_ sender: TabBarButton) {
        selectTab(at: sender.tag)
        selectedIndexRelay.accept(sender.tag)
    }

    func selectTab(at index: Int) {
        tabButtons.enumerated().forEach { offset, button in
            button.isSelected = (offset == index)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.pin.all()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 80)
    }
}

final class TabBarButton: UIControl {
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel().then {
        $0.textAlignment = .center
    }

    private let item: TabBarItem

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    init(item: TabBarItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)

        titleLabel.typography(FontSystem.Pretendard.caption1, text: item.title)
    }

    private func updateAppearance() {
        if isSelected {
            iconImageView.image = item.fillIcon?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = ColorSystem.gray90
            titleLabel.textColor = ColorSystem.gray90
        } else {
            iconImageView.image = item.emptyIcon?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = ColorSystem.gray45
            titleLabel.textColor = ColorSystem.gray45
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        iconImageView.pin
            .top(9)
            .hCenter()
            .size(24)

        titleLabel.pin
            .below(of: iconImageView)
            .marginTop(4)
            .horizontally()
            .sizeToFit(.width)
    }
}

@available(iOS 17.0, *)
#Preview("TabBar - Home Selected") {
    TabBar()
}

@available(iOS 17.0, *)
#Preview("TabBar - Favorites Selected") {
    TabBar().then {
        $0.selectTab(at: 1)
    }
}

@available(iOS 17.0, *)
#Preview("TabBar - Settings Selected") {
    TabBar().then {
        $0.selectTab(at: 2)
    }
}
