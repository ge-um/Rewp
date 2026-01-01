//
//  EstateDetailViewController.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import UIKit
import PinLayout
import RxSwift
import Then

final class EstateDetailViewController: UIViewController {
    var presenter: EstateDetailPresenter!
    var container: AppContainer!

    private let estateId: String
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var navigationBar = CustomNavigationBar(title: "문래동 롯데캐슬", showBackButton: true, showRightButton: true)

    private let imageCarousel = ImageCarousel()

    private let badgeContainer = UIView().then {
        $0.layer.borderColor = ColorSystem.deepCoast.cgColor
        $0.layer.borderWidth = 1.5
        $0.layer.cornerRadius = 12
    }

    private let diamondImageView = UIImageView().then {
        $0.image = UIImage(named: "Safty")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.deepCoast
        $0.contentMode = .scaleAspectFit
    }

    private let badgeLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1, text: "구매자 안심매물")
        $0.textColor = ColorSystem.deepCoast
    }

    private let timeLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body3, text: "2달 전")
        $0.textColor = ColorSystem.gray45
    }

    private let addressLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "서울 영등포구 선유로9길 30")
        $0.textColor = ColorSystem.gray60
    }

    private let priceContainer = UIView()

    private let priceTypeLabel = UILabel().then {
        $0.typography(FontSystem.YeongdeokHaeparang.title1, text: "월세")
        $0.textColor = ColorSystem.gray75
    }

    private let priceLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title0, text: "900/120")
        $0.textColor = ColorSystem.gray90
    }

    private let managementFeeLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "관리비 16만원 • 112.4m²")
        $0.textColor = ColorSystem.gray60
    }

    init(estateId: String) {
        self.estateId = estateId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupUI()
        bind()
    }

    private func setupUI() {
        view.addSubview(navigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(imageCarousel)
        contentView.addSubview(badgeContainer)
        badgeContainer.addSubview(diamondImageView)
        badgeContainer.addSubview(badgeLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(priceContainer)
        priceContainer.addSubview(priceTypeLabel)
        priceContainer.addSubview(priceLabel)
        contentView.addSubview(managementFeeLabel)
    }

    private func bind() {
        navigationBar.onBackButtonTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        navigationBar.onRightButtonTapped = {
            print("찜하기 버튼 탭")
        }

        imageCarousel.onImageTapped = { index in
            print("이미지 탭: \(index)")
        }

        imageCarousel.configure(with: [
            nil,
            nil,
            nil,
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        scrollView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()

        contentView.pin
            .top()
            .horizontally()
            .minHeight(scrollView.frame.height)

        imageCarousel.pin
            .top()
            .horizontally()
            .height(250)

        diamondImageView.pin
            .left(6)
            .top(4)
            .size(16)

        badgeLabel.pin
            .after(of: diamondImageView)
            .marginLeft(4)
            .marginRight(10)
            .vCenter(to: diamondImageView.edge.vCenter)
            .width(76)
            .height(14)

        badgeContainer.pin
            .below(of: imageCarousel)
            .marginTop(16)
            .left(20)
            .width(112)
            .height(24)

        timeLabel.pin
            .vCenter(to: badgeContainer.edge.vCenter)
            .right(20)
            .sizeToFit()

        addressLabel.pin
            .below(of: badgeContainer)
            .marginTop(8)
            .left(20)
            .sizeToFit()

        priceContainer.pin
            .below(of: addressLabel)
            .marginTop(4)
            .left(20)

        priceTypeLabel.pin
            .left()
            .bottom(4)
            .sizeToFit()

        priceLabel.pin
            .after(of: priceTypeLabel)
            .bottom()
            .marginLeft(4)
            .sizeToFit()

        priceContainer.pin
            .wrapContent()

        managementFeeLabel.pin
            .below(of: priceContainer)
            .marginTop(4)
            .left(20)
            .sizeToFit()

        contentView.pin
            .horizontally()
            .height(managementFeeLabel.frame.maxY + 20)

        scrollView.contentSize = contentView.frame.size
    }
}
