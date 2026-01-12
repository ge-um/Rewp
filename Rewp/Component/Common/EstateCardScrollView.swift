//
//  EstateCardScrollView.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import UIKit
import PinLayout
import Then
import RxSwift
import RxCocoa

final class EstateCardScrollView: UIView {
    var onCardTapped: ((String) -> Void)?

    private var estates: [EstateDTO] = []
    private let disposeBag = DisposeBag()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.delegate = self
        cv.dataSource = self
        cv.register(EstateCardCell.self, forCellWithReuseIdentifier: EstateCardCell.identifier)
        return cv
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(collectionView)
    }

    private func bindPageControl() {
        Observable.merge(
            collectionView.rx.didEndDecelerating.asObservable(),
            collectionView.rx.didEndScrollingAnimation.asObservable()
        )
        .withUnretained(self)
        .subscribe(onNext: { owner, _ in
            let pageWidth = owner.collectionView.bounds.width
            guard pageWidth > 0 else { return }

        })
        .disposed(by: disposeBag)
    }

    func configure(estates: [EstateDTO]) {
        self.estates = estates
        collectionView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        collectionView.pin
            .top()
            .horizontally()
            .bottom()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 166)
    }
}

extension EstateCardScrollView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return estates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EstateCardCell.identifier, for: indexPath) as! EstateCardCell
        cell.configure(estate: estates[indexPath.item])
        return cell
    }
}

extension EstateCardScrollView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let estate = estates[indexPath.item]
        onCardTapped?(estate.estate_id)
    }
}

extension EstateCardScrollView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: 132)
    }
}

final class EstateCardCell: UICollectionViewCell, IsIdentifiable {
    private let cardView = EstateCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(estate: EstateDTO) {
        cardView.configure(estate: estate)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.pin
            .horizontally(20)
            .vCenter()
            .height(132)
    }
}
