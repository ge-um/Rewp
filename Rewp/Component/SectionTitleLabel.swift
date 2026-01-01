//
//  SectionTitleLabel.swift
//  Rewp
//
//  Created by 금가경 on 12/25/25.
//

import UIKit
import FlexLayout
import PinLayout
import Then
import RxSwift
import RxCocoa

final class SectionTitleLabel: UIView {
    private let containerView = UIView()

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
        
    }

    private let viewAllButton = UIButton(type: .system).then {
        $0.setTitle("View All", for: .normal)
        $0.titleLabel?.typography(FontSystem.Pretendard.caption1Semibold)
        $0.setTitleColor(ColorSystem.deepCoast, for: .normal)
    }

    var viewAllTap: Observable<Void> {
        return viewAllButton.rx.tap.asObservable()
    }

    private let showViewAll: Bool

    init(title: String, showViewAll: Bool = true) {
        self.showViewAll = showViewAll
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body2, text: title)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)

        containerView.flex
            .direction(.row)
            .justifyContent(.spaceBetween)
            .alignItems(.center)
            .define { flex in
                flex.addItem(titleLabel)
                if showViewAll {
                    flex.addItem(viewAllButton)
                }
            }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.pin.all()
        containerView.flex.layout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        containerView.pin.width(size.width)
        containerView.flex.layout(mode: .adjustHeight)
        return containerView.frame.size
    }
}
