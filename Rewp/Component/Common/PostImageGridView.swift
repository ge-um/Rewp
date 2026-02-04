//
//  PostImageGridView.swift
//  Rewp
//
//  Created by 금가경 on 02/04/26.
//

import UIKit
import FlexLayout
import PinLayout
import Then
import Kingfisher

final class PostImageGridView: UIView {

    private let spacing: CGFloat = 2
    private let cornerRadius: CGFloat = 12

    private var imageViews: [UIImageView] = []
    private var imageURLs: [String] = []
    private var aspectRatios: [CGFloat] = []
    private var containerWidth: CGFloat = 0
    private var onImageTapped: ((Int) -> Void)?
    private var onLayoutComplete: (() -> Void)?

    private let flexContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(flexContainer)
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
    }

    func configure(
        with imageURLs: [String],
        containerWidth: CGFloat,
        onImageTapped: ((Int) -> Void)? = nil,
        onLayoutComplete: (() -> Void)? = nil
    ) {
        self.imageURLs = imageURLs
        self.containerWidth = containerWidth
        self.onImageTapped = onImageTapped
        self.onLayoutComplete = onLayoutComplete

        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        aspectRatios = Array(repeating: 1.0, count: imageURLs.count)

        guard !imageURLs.isEmpty else { return }

        for (index, _) in imageURLs.enumerated() {
            let imageView = createImageView(index: index)
            imageViews.append(imageView)
        }

        loadImagesAndLayout()
    }

    private func createImageView(index: Int) -> UIImageView {
        let imageView = UIImageView().then {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            $0.backgroundColor = ColorSystem.gray30
            $0.isUserInteractionEnabled = true
            $0.tag = index
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.addGestureRecognizer(tapGesture)

        return imageView
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view else { return }
        onImageTapped?(imageView.tag)
    }

    private func loadImagesAndLayout() {
        let dispatchGroup = DispatchGroup()

        for (index, urlString) in imageURLs.enumerated() {
            guard let url = URL(string: urlString) else { continue }

            dispatchGroup.enter()

            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                let aspectRatio: CGFloat
                let image: UIImage?

                switch result {
                case .success(let imageResult):
                    image = imageResult.image
                    aspectRatio = imageResult.image.size.width / imageResult.image.size.height
                case .failure:
                    image = nil
                    aspectRatio = 1.0
                }

                DispatchQueue.main.async {
                    self?.aspectRatios[index] = aspectRatio
                    if let image = image {
                        self?.imageViews[index].image = image
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.buildLayout()
        }
    }

    private func buildLayout() {
        flexContainer.subviews.forEach { $0.removeFromSuperview() }
        flexContainer.flex.direction(.column).define { _ in }

        let count = imageViews.count
        guard count > 0 else { return }

        switch count {
        case 1:
            buildSingleImageLayout()
        case 2:
            buildTwoImagesLayout()
        case 3:
            buildThreeImagesLayout()
        case 4:
            buildFourImagesLayout()
        default:
            buildFiveOrMoreImagesLayout()
        }

        applyCornerRadius()
        setNeedsLayout()
        layoutIfNeeded()
        onLayoutComplete?()
    }

    private func buildSingleImageLayout() {
        let imageView = imageViews[0]
        let aspectRatio = aspectRatios[0]
        let height = containerWidth / aspectRatio
        let clampedHeight = min(max(height, 150), 400)

        flexContainer.flex.direction(.column).define { flex in
            flex.addItem(imageView)
                .width(100%)
                .height(clampedHeight)
        }
    }

    private func buildTwoImagesLayout() {
        let firstIsPortrait = aspectRatios[0] < 1.0
        let secondIsPortrait = aspectRatios[1] < 1.0

        if firstIsPortrait && secondIsPortrait {
            let itemWidth = (containerWidth - spacing) / 2
            let height = itemWidth / min(aspectRatios[0], aspectRatios[1])
            let clampedHeight = min(height, 300)

            flexContainer.flex.direction(.row).define { flex in
                flex.addItem(imageViews[0])
                    .width(itemWidth)
                    .height(clampedHeight)
                flex.addItem(imageViews[1])
                    .width(itemWidth)
                    .height(clampedHeight)
                    .marginLeft(spacing)
            }
        } else {
            let itemWidth = (containerWidth - spacing) / 2
            let height = itemWidth

            flexContainer.flex.direction(.row).define { flex in
                flex.addItem(imageViews[0])
                    .width(itemWidth)
                    .height(height)
                flex.addItem(imageViews[1])
                    .width(itemWidth)
                    .height(height)
                    .marginLeft(spacing)
            }
        }
    }

    private func buildThreeImagesLayout() {
        let firstIsPortrait = aspectRatios[0] < 0.9

        if firstIsPortrait {
            let leftWidth = containerWidth * 0.5
            let rightWidth = containerWidth - leftWidth - spacing
            let totalHeight = leftWidth / aspectRatios[0]
            let clampedHeight = min(totalHeight, 300)
            let rightItemHeight = (clampedHeight - spacing) / 2

            flexContainer.flex.direction(.row).define { flex in
                flex.addItem(imageViews[0])
                    .width(leftWidth)
                    .height(clampedHeight)

                flex.addItem()
                    .direction(.column)
                    .width(rightWidth)
                    .marginLeft(spacing)
                    .define { column in
                        column.addItem(imageViews[1])
                            .width(100%)
                            .height(rightItemHeight)
                        column.addItem(imageViews[2])
                            .width(100%)
                            .height(rightItemHeight)
                            .marginTop(spacing)
                    }
            }
        } else {
            let topHeight = containerWidth / aspectRatios[0] * 0.6
            let clampedTopHeight = min(topHeight, 200)
            let bottomItemWidth = (containerWidth - spacing) / 2
            let bottomHeight = bottomItemWidth

            flexContainer.flex.direction(.column).define { flex in
                flex.addItem(imageViews[0])
                    .width(100%)
                    .height(clampedTopHeight)

                flex.addItem()
                    .direction(.row)
                    .marginTop(spacing)
                    .define { row in
                        row.addItem(imageViews[1])
                            .width(bottomItemWidth)
                            .height(bottomHeight)
                        row.addItem(imageViews[2])
                            .width(bottomItemWidth)
                            .height(bottomHeight)
                            .marginLeft(spacing)
                    }
            }
        }
    }

    private func buildFourImagesLayout() {
        let firstIsPortrait = aspectRatios[0] < 0.9

        if firstIsPortrait {
            let leftWidth = containerWidth * 0.5
            let rightWidth = containerWidth - leftWidth - spacing
            let totalHeight: CGFloat = 300
            let rightItemHeight = (totalHeight - spacing * 2) / 3

            flexContainer.flex.direction(.row).define { flex in
                flex.addItem(imageViews[0])
                    .width(leftWidth)
                    .height(totalHeight)

                flex.addItem()
                    .direction(.column)
                    .width(rightWidth)
                    .marginLeft(spacing)
                    .define { column in
                        column.addItem(imageViews[1])
                            .width(100%)
                            .height(rightItemHeight)
                        column.addItem(imageViews[2])
                            .width(100%)
                            .height(rightItemHeight)
                            .marginTop(spacing)
                        column.addItem(imageViews[3])
                            .width(100%)
                            .height(rightItemHeight)
                            .marginTop(spacing)
                    }
            }
        } else {
            let itemWidth = (containerWidth - spacing) / 2
            let itemHeight = itemWidth

            flexContainer.flex.direction(.column).define { flex in
                flex.addItem()
                    .direction(.row)
                    .define { row in
                        row.addItem(imageViews[0])
                            .width(itemWidth)
                            .height(itemHeight)
                        row.addItem(imageViews[1])
                            .width(itemWidth)
                            .height(itemHeight)
                            .marginLeft(spacing)
                    }

                flex.addItem()
                    .direction(.row)
                    .marginTop(spacing)
                    .define { row in
                        row.addItem(imageViews[2])
                            .width(itemWidth)
                            .height(itemHeight)
                        row.addItem(imageViews[3])
                            .width(itemWidth)
                            .height(itemHeight)
                            .marginLeft(spacing)
                    }
            }
        }
    }

    private func buildFiveOrMoreImagesLayout() {
        let count = imageViews.count
        let firstIsPortrait = aspectRatios[0] < 0.9

        if firstIsPortrait && count >= 5 {
            let leftWidth = containerWidth * 0.5
            let rightWidth = containerWidth - leftWidth - spacing
            let totalHeight: CGFloat = 300

            let rightImageCount = min(count - 1, 4)
            let rightItemHeight = (totalHeight - spacing * CGFloat(rightImageCount - 1)) / CGFloat(rightImageCount)

            flexContainer.flex.direction(.row).define { flex in
                flex.addItem(imageViews[0])
                    .width(leftWidth)
                    .height(totalHeight)

                flex.addItem()
                    .direction(.column)
                    .width(rightWidth)
                    .marginLeft(spacing)
                    .define { column in
                        for i in 1..<min(count, 5) {
                            if i == 1 {
                                column.addItem(imageViews[i])
                                    .width(100%)
                                    .height(rightItemHeight)
                            } else {
                                column.addItem(imageViews[i])
                                    .width(100%)
                                    .height(rightItemHeight)
                                    .marginTop(spacing)
                            }
                        }
                    }
            }

            if count > 5 {
                addMoreIndicator(to: imageViews[4], remainingCount: count - 5)
            }
        } else {
            let topCount = min(3, count)
            let bottomCount = min(count - topCount, 2)

            let topItemWidth = (containerWidth - spacing * CGFloat(topCount - 1)) / CGFloat(topCount)
            let topItemHeight = topItemWidth

            flexContainer.flex.direction(.column).define { flex in
                flex.addItem()
                    .direction(.row)
                    .define { row in
                        for i in 0..<topCount {
                            if i == 0 {
                                row.addItem(imageViews[i])
                                    .width(topItemWidth)
                                    .height(topItemHeight)
                            } else {
                                row.addItem(imageViews[i])
                                    .width(topItemWidth)
                                    .height(topItemHeight)
                                    .marginLeft(spacing)
                            }
                        }
                    }

                if bottomCount > 0 {
                    let bottomItemWidth = (containerWidth - spacing * CGFloat(bottomCount - 1)) / CGFloat(bottomCount)
                    let bottomItemHeight = bottomItemWidth

                    flex.addItem()
                        .direction(.row)
                        .marginTop(spacing)
                        .define { row in
                            for i in 0..<bottomCount {
                                let index = topCount + i
                                if i == 0 {
                                    row.addItem(imageViews[index])
                                        .width(bottomItemWidth)
                                        .height(bottomItemHeight)
                                } else {
                                    row.addItem(imageViews[index])
                                        .width(bottomItemWidth)
                                        .height(bottomItemHeight)
                                        .marginLeft(spacing)
                                }
                            }
                        }
                }
            }

            if count > 5 {
                let lastVisibleIndex = min(4, count - 1)
                addMoreIndicator(to: imageViews[lastVisibleIndex], remainingCount: count - 5)
            }
        }
    }

    private func addMoreIndicator(to imageView: UIImageView, remainingCount: Int) {
        let overlay = UIView().then {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }

        let label = UILabel().then {
            $0.textColor = .white
            $0.textAlignment = .center
        }
        label.typography(FontSystem.Pretendard.title1Bold, text: "+\(remainingCount)")

        imageView.addSubview(overlay)
        overlay.addSubview(label)

        overlay.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
    }

    private func applyCornerRadius() {
        guard !imageViews.isEmpty else { return }

        imageViews.forEach { $0.layer.cornerRadius = 0 }

        let count = imageViews.count
        let firstIsPortrait = aspectRatios.first.map { $0 < 0.9 } ?? false

        switch count {
        case 1:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        case 2:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            imageViews[1].layer.cornerRadius = cornerRadius
            imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        case 3:
            if firstIsPortrait {
                imageViews[0].layer.cornerRadius = cornerRadius
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[1].layer.cornerRadius = cornerRadius
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[2].layer.cornerRadius = cornerRadius
                imageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
            } else {
                imageViews[0].layer.cornerRadius = cornerRadius
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                imageViews[1].layer.cornerRadius = cornerRadius
                imageViews[1].layer.maskedCorners = [.layerMinXMaxYCorner]
                imageViews[2].layer.cornerRadius = cornerRadius
                imageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
            }

        case 4:
            if firstIsPortrait {
                imageViews[0].layer.cornerRadius = cornerRadius
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[1].layer.cornerRadius = cornerRadius
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[3].layer.cornerRadius = cornerRadius
                imageViews[3].layer.maskedCorners = [.layerMaxXMaxYCorner]
            } else {
                imageViews[0].layer.cornerRadius = cornerRadius
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]
                imageViews[1].layer.cornerRadius = cornerRadius
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[2].layer.cornerRadius = cornerRadius
                imageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
                imageViews[3].layer.cornerRadius = cornerRadius
                imageViews[3].layer.maskedCorners = [.layerMaxXMaxYCorner]
            }

        default:
            if firstIsPortrait {
                imageViews[0].layer.cornerRadius = cornerRadius
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                if imageViews.count > 1 {
                    imageViews[1].layer.cornerRadius = cornerRadius
                    imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                }
                let lastRightIndex = min(4, imageViews.count - 1)
                if lastRightIndex > 1 {
                    imageViews[lastRightIndex].layer.cornerRadius = cornerRadius
                    imageViews[lastRightIndex].layer.maskedCorners = [.layerMaxXMaxYCorner]
                }
            } else {
                imageViews[0].layer.cornerRadius = cornerRadius
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]

                let topCount = min(3, imageViews.count)
                if topCount > 1 {
                    imageViews[topCount - 1].layer.cornerRadius = cornerRadius
                    imageViews[topCount - 1].layer.maskedCorners = [.layerMaxXMinYCorner]
                }

                if imageViews.count > topCount {
                    imageViews[topCount].layer.cornerRadius = cornerRadius
                    imageViews[topCount].layer.maskedCorners = [.layerMinXMaxYCorner]

                    let lastIndex = min(4, imageViews.count - 1)
                    if lastIndex > topCount {
                        imageViews[lastIndex].layer.cornerRadius = cornerRadius
                        imageViews[lastIndex].layer.maskedCorners = [.layerMaxXMaxYCorner]
                    } else {
                        imageViews[topCount].layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    }
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        flexContainer.pin.all()
        flexContainer.flex.layout()
    }

    func calculateHeight() -> CGFloat {
        let count = imageViews.count
        guard count > 0 else { return 0 }

        let firstIsPortrait = aspectRatios.first.map { $0 < 0.9 } ?? false

        switch count {
        case 1:
            let height = containerWidth / aspectRatios[0]
            return min(max(height, 150), 400)

        case 2:
            if aspectRatios[0] < 1.0 && aspectRatios[1] < 1.0 {
                let itemWidth = (containerWidth - spacing) / 2
                let height = itemWidth / min(aspectRatios[0], aspectRatios[1])
                return min(height, 300)
            } else {
                return (containerWidth - spacing) / 2
            }

        case 3:
            if firstIsPortrait {
                let leftWidth = containerWidth * 0.5
                let height = leftWidth / aspectRatios[0]
                return min(height, 300)
            } else {
                let topHeight = containerWidth / aspectRatios[0] * 0.6
                let clampedTopHeight = min(topHeight, 200)
                let bottomItemWidth = (containerWidth - spacing) / 2
                return clampedTopHeight + spacing + bottomItemWidth
            }

        case 4:
            if firstIsPortrait {
                return 300
            } else {
                let itemWidth = (containerWidth - spacing) / 2
                return itemWidth * 2 + spacing
            }

        default:
            if firstIsPortrait {
                return 300
            } else {
                let topCount = min(3, count)
                let bottomCount = min(count - topCount, 2)
                let topItemWidth = (containerWidth - spacing * CGFloat(topCount - 1)) / CGFloat(topCount)

                if bottomCount > 0 {
                    let bottomItemWidth = (containerWidth - spacing * CGFloat(bottomCount - 1)) / CGFloat(bottomCount)
                    return topItemWidth + spacing + bottomItemWidth
                } else {
                    return topItemWidth
                }
            }
        }
    }
}
