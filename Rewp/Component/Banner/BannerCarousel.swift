//
//  BannerCarousel.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import Then
import RxSwift
import RxCocoa
import Kingfisher

final class BannerCarouselCell: UICollectionViewCell {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = ColorSystem.gray45
    }

    private let locationBackground = UIView().then {
        $0.backgroundColor = ColorSystem.gray60.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 10
    }

    private let locationIcon = UIImageView().then {
        $0.image = UIImage(named: "Location")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
    }

    private let locationLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption2, text: "")
        $0.textColor = .white
    }

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Paperlogy.title1, text: "")
        $0.textColor = .white
        $0.numberOfLines = 2
    }

    private let descriptionLabel = UILabel().then {
        $0.typography(FontSystem.Paperlogy.caption1, text: "")
        $0.textColor = .white.withAlphaComponent(0.8)
        $0.numberOfLines = 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(locationBackground)
        contentView.addSubview(locationIcon)
        contentView.addSubview(locationLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.pin.all()

        descriptionLabel.pin
            .left(20)
            .right(20)
            .bottom(40)
            .sizeToFit(.width)

        titleLabel.pin
            .left(20)
            .right(20)
            .above(of: descriptionLabel)
            .marginBottom(8)
            .sizeToFit(.width)

        locationLabel.pin
            .sizeToFit(.widthFlexible)

        let backgroundWidth = 4 + 16 + 2 + locationLabel.frame.width + 6

        locationBackground.pin
            .left(20)
            .above(of: titleLabel)
            .marginBottom(4)
            .width(backgroundWidth)
            .height(20)

        locationIcon.pin
            .left(24)
            .vCenter(to: locationBackground.edge.vCenter)
            .size(16)

        locationLabel.pin
            .after(of: locationIcon)
            .marginLeft(2)
            .vCenter(to: locationIcon.edge.vCenter)
            .sizeToFit(.widthFlexible)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.backgroundColor = ColorSystem.gray45
    }

    func configure(with item: BannerItem) {
        locationLabel.typography(FontSystem.Pretendard.caption2, text: item.location)
        titleLabel.typography(FontSystem.Paperlogy.title1, text: item.title)
        descriptionLabel.typography(FontSystem.Paperlogy.caption1, text: item.description)

        imageView.setImage(from: item.imageURL)

        if item.imageURL == nil {
            imageView.backgroundColor = ColorSystem.gray45
        }
    }
}

final class BannerCarousel: UIView {
    private let bannersRelay = BehaviorRelay<[BannerItem]>(value: [])
    private let disposeBag = DisposeBag()

    var onBannerTapped: ((String) -> Void)?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.delegate = self
        cv.register(BannerCarouselCell.self, forCellWithReuseIdentifier: "BannerCarouselCell")
        return cv
    }()

    private let pageControl = UIPageControl().then {
        $0.currentPageIndicatorTintColor = ColorSystem.gray30
        $0.pageIndicatorTintColor = ColorSystem.gray75
        $0.hidesForSinglePage = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(collectionView)
        addSubview(pageControl)
    }

    private func bind() {
        bannersRelay
            .bind(to: collectionView.rx.items(
                cellIdentifier: "BannerCarouselCell",
                cellType: BannerCarouselCell.self
            )) { index, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        bannersRelay
            .map { $0.count }
            .withUnretained(self)
            .subscribe(onNext: { owner, count in
                owner.pageControl.numberOfPages = count
            })
            .disposed(by: disposeBag)

        Observable.merge(
            collectionView.rx.didEndDecelerating.asObservable(),
            collectionView.rx.didEndScrollingAnimation.asObservable()
        )
        .withUnretained(self)
        .subscribe(onNext: { owner, _ in
            let pageWidth = owner.collectionView.bounds.width
            guard pageWidth > 0 else { return }
            let page = Int(round(owner.collectionView.contentOffset.x / pageWidth))
            owner.pageControl.currentPage = page
        })
        .disposed(by: disposeBag)

        collectionView.rx.modelSelected(BannerItem.self)
            .withUnretained(self)
            .subscribe(onNext: { owner, item in
                owner.onBannerTapped?(item.id)
            })
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        collectionView.pin.all()

        pageControl.pin
            .hCenter()
            .bottom(16)
            .height(20)
    }

    func configure(with banners: [BannerItem]) {
        bannersRelay.accept(banners)
        collectionView.reloadData()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 335)
    }
}

extension BannerCarousel: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}

@available(iOS 17.0, *)
#Preview {
    let carousel = BannerCarousel()
    carousel.configure(with: [
        BannerItem(
            id: "1",
            imageURL: nil,
            location: "서울 반포동",
            title: "한강 파노라마 뷰\n역세권 아파트",
            description: "외국 무료 사진 퍼온 것 같겠지만 한강입니다."
        ),
        BannerItem(
            id: "2",
            imageURL: nil,
            location: "서울 강남구",
            title: "신축 오피스텔\n특별 분양",
            description: "강남역 도보 5분 거리"
        )
    ])
    return carousel
}
