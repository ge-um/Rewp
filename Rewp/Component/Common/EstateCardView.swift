//
//  EstateCardView.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import UIKit
import PinLayout
import FlexLayout
import Then
import Kingfisher
import RxSwift

final class EstateCardView: UIView {
    private let disposeBag = DisposeBag()

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 12
        $0.layer.applyShadow(ShadowSystem.md)
    }

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = ColorSystem.gray15
    }

    private let categoryBadge = UILabel().then {
        $0.textColor = ColorSystem.brightWood
        $0.layer.borderWidth = 1
        $0.layer.borderColor = ColorSystem.brightWood.cgColor
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.textAlignment = .center
        $0.baselineAdjustment = .alignCenters
    }

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let priceLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let infoLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private let addressLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private let rightContentContainer = UIView()
    private let topRowContainer = UIView()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)

        containerView.flex
            .direction(.row)
            .height(132)
            .alignItems(.center)
            .paddingHorizontal(12)
            .grow(1)
            .define { flex in
                flex.addItem(thumbnailImageView)
                    .size(100)

                flex.addItem(rightContentContainer)
                    .direction(.column)
                    .paddingHorizontal(12)
                    .grow(1)
                    .shrink(1)
                    .define { flex in
                        flex.addItem(topRowContainer)
                            .direction(.row)
                            .alignItems(.center)
                            .marginBottom(4)
                            .width(100%)
                            .define { flex in
                                flex.addItem(categoryBadge)
                                    .width(36)
                                    .height(16)
                                    .paddingHorizontal(6)

                                flex.addItem(titleLabel)
                                    .marginLeft(6)
                                    .height(16)
                                    .grow(1)
                                    .shrink(1)
                            }

                        flex.addItem(priceLabel)
                            .marginBottom(4)
                            .width(100%)

                        flex.addItem(infoLabel)
                            .marginBottom(4)
                            .width(100%)

                        flex.addItem(addressLabel)
                            .width(100%)
                    }
            }
    }

    func configure(estate: EstateDTO) {
        if let thumbnailPath = estate.thumbnails.first {
            let imageURL = URL(string: NetworkConfig.baseURL + thumbnailPath)
            thumbnailImageView.kf.setImage(with: imageURL)
        } else {
            thumbnailImageView.image = nil
        }

        categoryBadge.typography(FontSystem.Pretendard.caption3Semibold, text: estate.category)
        titleLabel.typography(FontSystem.Pretendard.body2Bold, text: estate.title)

        let depositInManwon = estate.deposit / 10000
        let rentInManwon = estate.monthly_rent / 10000
        let priceText = estate.monthly_rent == 0
            ? "전세 \(depositInManwon.formatted())"
            : "월세 \(depositInManwon.formatted())/\(rentInManwon.formatted())"
        priceLabel.typography(FontSystem.Pretendard.title1Bold, text: priceText)

        infoLabel.typography(FontSystem.Pretendard.caption1Medium, text: "\(estate.area)m² · \(estate.floors)층")

        addressLabel.typography(FontSystem.Pretendard.caption1Medium, text: "주소 확인 중...")
        loadAddress(latitude: estate.geolocation.latitude, longitude: estate.geolocation.longitude)
    }

    private func loadAddress(latitude: Double, longitude: Double) {
        GeocodeService.shared
            .reverseGeocode(latitude: latitude, longitude: longitude)
            .asObservable()
            .observe(on: MainScheduler.instance)
            .catch { _ in
                return .just("주소 확인 실패")
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, address in
                owner.addressLabel.typography(FontSystem.Pretendard.caption1Medium, text: address)
            })
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.pin.all()
        containerView.flex.layout(mode: .adjustHeight)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 166)
    }
}
