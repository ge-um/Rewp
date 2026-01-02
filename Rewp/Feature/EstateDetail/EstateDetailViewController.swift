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
import OSLog

final class EstateDetailViewController: UIViewController {
    var presenter: EstateDetailPresenter!
    var container: AppContainer!

    private let estateId: String
    private let disposeBag = DisposeBag()
    private let viewDidLoadTrigger = PublishSubject<Void>()

    private let scrollView = UIScrollView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.showsVerticalScrollIndicator = false
    }

    private lazy var navigationBar = CustomNavigationBar(title: "", showBackButton: true, showRightButton: true)

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
        $0.typography(FontSystem.Pretendard.body3, text: "")
        $0.textColor = ColorSystem.gray45
    }

    private let addressLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "")
        $0.textColor = ColorSystem.gray60
    }

    private let priceContainer = UIView()

    private let priceTypeLabel = UILabel().then {
        $0.typography(FontSystem.YeongdeokHaeparang.title1, text: "")
        $0.textColor = ColorSystem.gray75
    }

    private let priceLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title0, text: "")
        $0.textColor = ColorSystem.gray90
    }

    private let managementFeeLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "")
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
        $0.typography(FontSystem.Pretendard.caption1Semibold, text: "")
        $0.textColor = ColorSystem.gray60
    }

    private let descriptionDivider = ItemDivider()

    private let descriptionTitleLabel = DetailTitle(title: "상세 설명")

    private let descriptionLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1Regular, text: "")
        $0.textColor = ColorSystem.gray60
        $0.numberOfLines = 0
    }

    private let agentDivider = ItemDivider()

    private let agentTitleLabel = DetailTitle(title: "중개사 정보")

    private let agentContainer = UIView()

    private let agentProfileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 30
        $0.backgroundColor = ColorSystem.gray30
    }

    private let agentNameLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body1Bold, text: "")
        $0.textColor = ColorSystem.gray90
    }

    private let agentDescriptionLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body3, text: "")
        $0.textColor = ColorSystem.gray60
    }

    private let agentCallButton = UIButton().then {
        let iconSize = CGSize(width: 24, height: 24)
        let icon = UIImage(named: "Phone")?
            .resize(to: iconSize)
            .withRenderingMode(.alwaysTemplate)
        $0.setImage(icon, for: .normal)
        $0.tintColor = ColorSystem.gray0
        $0.backgroundColor = ColorSystem.deepCream
        $0.layer.cornerRadius = 10
        $0.imageView?.contentMode = .center
    }

    private let agentChatButton = UIButton().then {
        let iconSize = CGSize(width: 24, height: 24)
        let icon = UIImage(named: "Message")?
            .resize(to: iconSize)
            .withRenderingMode(.alwaysTemplate)
        $0.setImage(icon, for: .normal)
        $0.tintColor = ColorSystem.gray0
        $0.backgroundColor = ColorSystem.deepCream
        $0.layer.cornerRadius = 10
        $0.imageView?.contentMode = .center
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

    private let bottomContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.shadowColor = ColorSystem.shadow.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: -2)
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowRadius = 6
    }

    private let reservationButton = UIButton().then {
        $0.setTitle("예약하기", for: .normal)
        $0.titleLabel?.font = FontSystem.Pretendard.body1Bold.font
        $0.setTitleColor(ColorSystem.gray0, for: .normal)
        $0.backgroundColor = ColorSystem.deepCream
        $0.layer.cornerRadius = 8
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
        scrollView.addSubview(agentDivider)
        scrollView.addSubview(agentTitleLabel)
        scrollView.addSubview(agentContainer)
        agentContainer.addSubview(agentProfileImageView)
        agentContainer.addSubview(agentNameLabel)
        agentContainer.addSubview(agentDescriptionLabel)
        agentContainer.addSubview(agentCallButton)
        agentContainer.addSubview(agentChatButton)
        scrollView.addSubview(similarEstatesDivider)
        scrollView.addSubview(similarEstatesTitleLabel)
        scrollView.addSubview(similarEstatesScrollView)
        similarEstatesScrollView.addSubview(similarEstatesContainerView)

        similarEstatesItems.forEach { item in
            similarEstatesContainerView.addSubview(item)
        }

        view.addSubview(bottomContainer)
        bottomContainer.addSubview(reservationButton)
    }

    private func bind() {
        let input = EstateDetailPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.estateDetail
            .drive(with: self) { owner, detail in
                owner.updateUI(with: detail)
            }
            .disposed(by: disposeBag)

        output.error
            .drive(with: self) { owner, message in
                let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        viewDidLoadTrigger.onNext(())

        navigationBar.onBackButtonTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        navigationBar.onRightButtonTapped = {
            print("찜하기 버튼 탭")
        }

        imageCarousel.onImageTapped = { index in
            print("이미지 탭: \(index)")
        }

        agentCallButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                print("전화 버튼 탭")
            })
            .disposed(by: disposeBag)

        agentChatButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                print("채팅 버튼 탭")
            })
            .disposed(by: disposeBag)

        reservationButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                print("예약하기 버튼 탭")
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        bottomContainer.pin
            .bottom(view.pin.safeArea.bottom)
            .horizontally()
            .height(48)

        reservationButton.pin
            .top(12)
            .horizontally(20)
            .height(48)

        scrollView.pin
            .below(of: navigationBar)
            .horizontally()
            .above(of: bottomContainer)

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
            .bottom()
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
            .marginTop(8)
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

        agentDivider.pin
            .below(of: similarEstatesScrollView)
            .marginTop(8)
            .horizontally()
            .sizeToFit(.width)

        agentTitleLabel.pin
            .below(of: agentDivider)
            .marginTop(5)
            .horizontally(20)
            .height(32)

        agentContainer.pin
            .below(of: agentTitleLabel)
            .marginTop(8)
            .horizontally(20)
            .height(60)

        agentProfileImageView.pin
            .vCenter()
            .size(60)

        if agentDescriptionLabel.isHidden {
            agentNameLabel.pin
                .after(of: agentProfileImageView)
                .marginLeft(12)
                .vCenter(to: agentProfileImageView.edge.vCenter)
                .sizeToFit()
        } else {
            agentNameLabel.pin
                .after(of: agentProfileImageView)
                .marginLeft(12)
                .top(to: agentProfileImageView.edge.top)
                .marginTop(9.5)
                .sizeToFit()

            agentDescriptionLabel.pin
                .after(of: agentProfileImageView)
                .marginLeft(12)
                .below(of: agentNameLabel)
                .marginTop(6)
                .sizeToFit()
        }

        agentChatButton.pin
            .right(0)
            .vCenter()
            .size(40)

        agentCallButton.pin
            .before(of: agentChatButton)
            .marginRight(8)
            .vCenter()
            .size(40)

        let contentHeight = agentContainer.frame.maxY + 20
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: contentHeight)
    }

    private func updateUI(with detail: EstateDetail) {
        navigationBar.setTitle(detail.title)
        imageCarousel.configure(with: detail.imageURLs)
        badgeContainer.isHidden = !detail.isSafeEstate
        timeLabel.typography(FontSystem.Pretendard.body3, text: detail.relativeTime)
        addressLabel.typography(FontSystem.Pretendard.body2, text: detail.category)
        priceTypeLabel.typography(FontSystem.YeongdeokHaeparang.title1, text: detail.priceType)
        priceLabel.typography(FontSystem.Pretendard.title0, text: detail.price)
        managementFeeLabel.typography(FontSystem.Pretendard.body2, text: detail.managementFeeText)

        let options = detail.options
        let optionLabels = [optionRefrigerator, optionWashingMachine, optionAirConditioner, optionMicrowave,
                           optionSink, optionTelevision, optionShoeCabinet, optionCloset]

        for (index, optionLabel) in optionLabels.enumerated() {
            if index < options.count {
                optionLabel.isSelected = true
            } else {
                optionLabel.isSelected = false
            }
        }

        parkingInfoLabel.typography(FontSystem.Pretendard.caption1Semibold, text: detail.parkingInfo)
        descriptionLabel.typography(FontSystem.Pretendard.caption1Regular, text: detail.description)
        agentNameLabel.typography(FontSystem.Pretendard.body1Bold, text: detail.creatorName)

        if detail.creatorIntroduction.isEmpty {
            agentDescriptionLabel.isHidden = true
        } else {
            agentDescriptionLabel.isHidden = false
            agentDescriptionLabel.typography(FontSystem.Pretendard.body3, text: detail.creatorIntroduction)
        }

        if let profileImageURL = detail.creatorProfileImageURL {
            agentProfileImageView.setImage(from: profileImageURL, placeholder: UIImage(named: "placeholder"))
        }

        navigationBar.setRightButtonImage(filled: detail.isLiked)

        view.setNeedsLayout()
    }
}
