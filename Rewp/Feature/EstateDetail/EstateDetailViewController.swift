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
        $0.backgroundColor = ColorSystem.gray0
        $0.showsVerticalScrollIndicator = false
    }

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
        $0.typography(FontSystem.Pretendard.caption1Semibold, text: "구매자 안심매물")
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

    private let divider = ItemDivider()

    private let optionTitleLabel = DetailTitle(title: "옵션 정보")

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
        $0.layer.cornerRadius = 16
    }

    private let parkingIconImageView = UIImageView().then {
        $0.image = UIImage(named: "Parking")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.gray60
        $0.contentMode = .scaleAspectFit
    }

    private let parkingInfoLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1Semibold, text: "세대별 차량 2대 주차 가능")
        $0.textColor = ColorSystem.gray60
    }

    private let descriptionDivider = ItemDivider()

    private let descriptionTitleLabel = DetailTitle(title: "상세 설명")

    private let descriptionLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1Regular, text: """
        서울 문래동에 위치한 문래동 롯데캐슬은 뛰어난 교통 접근성과 쾌적한 주거 환경을 갖춘 프리미엄 아파트입니다.

        지하철 2호선 문래역 도보권에 있으며, 다양한 커뮤니티 시설과 근교 마켓까지 모든 주거 편의들을 제공합니다.

        세대 내부는 실용적인 공간 설계를 갖추고있으며, 채광과 환기에도 신경 쓴 패밀리와 원인들에게 동시에 추천 드릴 수 있는 구성입니다.
        """)
        $0.textColor = ColorSystem.gray60
        $0.numberOfLines = 0
    }

    private let similarEstatesDivider = ItemDivider()

    private let similarEstatesTitleLabel = DetailTitle(title: "유사한 매물")

    private let similarEstatesScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private let similarEstatesContainerView = UIView()

    private lazy var similarEstatesItems: [RecentSearchItem] = [
        RecentSearchItem(recommend: "추천", category: "원룸", price: "월세 3,000/20", area: "문래동 112.4m²"),
        RecentSearchItem(category: "원룸", price: "월세 900/50", area: "문래동 49.5m²")
    ]

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

        scrollView.addSubview(imageCarousel)
        scrollView.addSubview(badgeContainer)
        badgeContainer.addSubview(diamondImageView)
        badgeContainer.addSubview(badgeLabel)
        scrollView.addSubview(timeLabel)
        scrollView.addSubview(addressLabel)
        scrollView.addSubview(priceContainer)
        priceContainer.addSubview(priceTypeLabel)
        priceContainer.addSubview(priceLabel)
        scrollView.addSubview(managementFeeLabel)
        scrollView.addSubview(divider)
        scrollView.addSubview(optionTitleLabel)
        scrollView.addSubview(optionGridContainer)
        optionGridContainer.addSubview(optionRefrigerator)
        optionGridContainer.addSubview(optionWashingMachine)
        optionGridContainer.addSubview(optionAirConditioner)
        optionGridContainer.addSubview(optionMicrowave)
        optionGridContainer.addSubview(optionSink)
        optionGridContainer.addSubview(optionTelevision)
        optionGridContainer.addSubview(optionShoeCabinet)
        optionGridContainer.addSubview(optionCloset)
        scrollView.addSubview(parkingInfoContainer)
        parkingInfoContainer.addSubview(parkingIconImageView)
        parkingInfoContainer.addSubview(parkingInfoLabel)
        scrollView.addSubview(descriptionDivider)
        scrollView.addSubview(descriptionTitleLabel)
        scrollView.addSubview(descriptionLabel)
        scrollView.addSubview(similarEstatesDivider)
        scrollView.addSubview(similarEstatesTitleLabel)
        scrollView.addSubview(similarEstatesScrollView)
        similarEstatesScrollView.addSubview(similarEstatesContainerView)

        similarEstatesItems.forEach { item in
            similarEstatesContainerView.addSubview(item)
        }
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

        divider.pin
            .below(of: managementFeeLabel)
            .marginTop(16)
            .horizontally()
            .sizeToFit(.width)

        optionTitleLabel.pin
            .below(of: divider)
            .marginTop(5)
            .horizontally(20)
            .height(32)

        optionGridContainer.pin
            .below(of: optionTitleLabel)
            .marginTop(8)
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
            .height(32)

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

        descriptionDivider.pin
            .below(of: parkingInfoContainer)
            .marginTop(16)
            .horizontally()
            .sizeToFit(.width)

        descriptionTitleLabel.pin
            .below(of: descriptionDivider)
            .marginTop(5)
            .horizontally(20)
            .height(32)

        descriptionLabel.pin
            .below(of: descriptionTitleLabel)
            .marginTop(8)
            .horizontally(20)
            .sizeToFit(.width)

        similarEstatesDivider.pin
            .below(of: descriptionLabel)
            .marginTop(24)
            .horizontally()
            .sizeToFit(.width)

        similarEstatesTitleLabel.pin
            .below(of: similarEstatesDivider)
            .marginTop(5)
            .horizontally(20)
            .height(32)

        similarEstatesScrollView.pin
            .below(of: similarEstatesTitleLabel)
            .horizontally(20)
            .height(104)

        var xOffset: CGFloat = 0
        similarEstatesItems.enumerated().forEach { index, item in
            item.pin
                .left(xOffset)
                .top()
                .size(item.intrinsicContentSize)
            xOffset += item.intrinsicContentSize.width + 8
        }

        similarEstatesContainerView.pin
            .top()
            .left()
            .width(xOffset - 8)
            .height(88)

        similarEstatesScrollView.contentSize = similarEstatesContainerView.frame.size

        let contentHeight = similarEstatesScrollView.frame.maxY + 20
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: contentHeight)
    }
}
