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

    private let scrollView = UIScrollView().then {
        $0.backgroundColor = ColorSystem.gray15
    }
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

    private let divider = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }

    private let optionTitleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body1, text: "옵션 정보")
        $0.textColor = ColorSystem.gray90
    }

    private let optionGridContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.borderColor = ColorSystem.gray30.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 20
    }

    private lazy var optionRefrigerator = OptionLabel(iconName: "Refrigerator", title: "냉장고").then {
        $0.isSelected = false
    }

    private lazy var optionWashingMachine = OptionLabel(iconName: "WashingMachine", title: "세탁기").then {
        $0.isSelected = true
    }

    private lazy var optionAirConditioner = OptionLabel(iconName: "AirConditioner", title: "에어컨").then {
        $0.isSelected = true
    }

    private lazy var optionMicrowave = OptionLabel(iconName: "Microwave", title: "전자레인지").then {
        $0.isSelected = false
    }

    private lazy var optionSink = OptionLabel(iconName: "Sink", title: "싱크대").then {
        $0.isSelected = true
    }

    private lazy var optionTelevision = OptionLabel(iconName: "Television", title: "TV").then {
        $0.isSelected = true
    }

    private lazy var optionShoeCabinet = OptionLabel(iconName: "ShoeCabinet", title: "신발장").then {
        $0.isSelected = true
    }

    private lazy var optionCloset = OptionLabel(iconName: "Closet", title: "옷장").then {
        $0.isSelected = false
    }

    private let parkingInfoContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.borderColor = ColorSystem.gray30.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 20
    }

    private let parkingIconImageView = UIImageView().then {
        $0.image = UIImage(named: "Parking")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.gray60
        $0.contentMode = .scaleAspectFit
    }

    private let parkingInfoLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1, text: "세대별 차량 2대 주차 가능")
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
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(navigationBar)
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
        contentView.addSubview(divider)
        contentView.addSubview(optionTitleLabel)
        contentView.addSubview(optionGridContainer)
        optionGridContainer.addSubview(optionRefrigerator)
        optionGridContainer.addSubview(optionWashingMachine)
        optionGridContainer.addSubview(optionAirConditioner)
        optionGridContainer.addSubview(optionMicrowave)
        optionGridContainer.addSubview(optionSink)
        optionGridContainer.addSubview(optionTelevision)
        optionGridContainer.addSubview(optionShoeCabinet)
        optionGridContainer.addSubview(optionCloset)
        contentView.addSubview(parkingInfoContainer)
        parkingInfoContainer.addSubview(parkingIconImageView)
        parkingInfoContainer.addSubview(parkingInfoLabel)
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

        scrollView.pin
            .all()

        contentView.pin
            .top()
            .horizontally()
            .width(scrollView.frame.width)

        navigationBar.pin
            .top()
            .horizontally()
            .height(56)

        imageCarousel.pin
            .below(of: navigationBar)
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

        divider.pin
            .below(of: managementFeeLabel)
            .marginTop(16)
            .horizontally(20)
            .height(1)

        optionTitleLabel.pin
            .below(of: divider)
            .marginTop(7.5)
            .left(20)
            .sizeToFit()

        optionGridContainer.pin
            .below(of: optionTitleLabel)
            .marginTop(15.5)
            .horizontally(20)

        let containerWidth = optionGridContainer.frame.width
        let itemWidth: CGFloat = 54
        let horizontalPadding: CGFloat = 25
        let spacing = (containerWidth - (horizontalPadding * 2) - (itemWidth * 4)) / 3

        optionRefrigerator.pin
            .top(19)
            .left(horizontalPadding)
            .size(54)

        optionWashingMachine.pin
            .top(19)
            .after(of: optionRefrigerator)
            .marginLeft(spacing)
            .size(54)

        optionAirConditioner.pin
            .top(19)
            .after(of: optionWashingMachine)
            .marginLeft(spacing)
            .size(54)

        optionMicrowave.pin
            .top(19)
            .after(of: optionAirConditioner)
            .marginLeft(spacing)
            .size(54)

        optionSink.pin
            .below(of: optionRefrigerator)
            .marginTop(16)
            .left(horizontalPadding)
            .size(54)

        optionTelevision.pin
            .below(of: optionWashingMachine)
            .marginTop(16)
            .after(of: optionSink)
            .marginLeft(spacing)
            .size(54)

        optionShoeCabinet.pin
            .below(of: optionAirConditioner)
            .marginTop(16)
            .after(of: optionTelevision)
            .marginLeft(spacing)
            .size(54)

        optionCloset.pin
            .below(of: optionMicrowave)
            .marginTop(16)
            .after(of: optionShoeCabinet)
            .marginLeft(spacing)
            .size(54)

        optionGridContainer.pin
            .height(optionCloset.frame.maxY + 19)

        parkingInfoContainer.pin
            .below(of: optionGridContainer)
            .marginTop(12)
            .left(20)
            .height(40)

        parkingIconImageView.pin
            .left(12.5)
            .vCenter()
            .size(20)

        parkingInfoLabel.pin
            .after(of: parkingIconImageView)
            .marginLeft(4)
            .vCenter()
            .sizeToFit()

        parkingInfoContainer.pin
            .width(parkingInfoLabel.frame.maxX + 12.5)

        contentView.pin
            .horizontally()
            .height(parkingInfoContainer.frame.maxY + 20)

        scrollView.contentSize = contentView.frame.size
    }
}
