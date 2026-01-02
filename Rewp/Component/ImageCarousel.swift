//
//  ImageCarousel.swift
//  Rewp
//
//  Created by 금가경 on 01/01/26.
//

import UIKit
import PinLayout
import Then
import RxSwift
import RxCocoa
import Kingfisher

final class ImageCarouselCell: UICollectionViewCell {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = ColorSystem.gray30
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.pin.all()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.backgroundColor = ColorSystem.gray30
    }

    func configure(with imageURL: String?) {
        imageView.setImage(from: imageURL)

        if imageURL == nil {
            imageView.backgroundColor = ColorSystem.gray30
        }
    }
}

final class ImageCarousel: UIView {
    private let imagesRelay = BehaviorRelay<[String?]>(value: [])
    private let disposeBag = DisposeBag()

    var onImageTapped: ((Int) -> Void)?

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
        cv.register(ImageCarouselCell.self, forCellWithReuseIdentifier: "ImageCarouselCell")
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
        imagesRelay
            .bind(to: collectionView.rx.items(
                cellIdentifier: "ImageCarouselCell",
                cellType: ImageCarouselCell.self
            )) { index, imageURL, cell in
                cell.configure(with: imageURL)
            }
            .disposed(by: disposeBag)

        imagesRelay
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

        collectionView.rx.itemSelected
            .map { $0.item }
            .withUnretained(self)
            .subscribe(onNext: { owner, index in
                owner.onImageTapped?(index)
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

    func configure(with imageURLs: [String?]) {
        let urls = imageURLs.isEmpty ? [nil] : imageURLs
        imagesRelay.accept(urls)
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        pageControl.currentPage = 0
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 250)
    }
}

extension ImageCarousel: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}
