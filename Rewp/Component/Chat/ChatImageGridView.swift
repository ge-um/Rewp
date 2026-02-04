//
//  ChatImageGridView.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import FlexLayout
import PinLayout
import Then
import Kingfisher

final class ChatImageGridView: UIView {

    static let maxWidth: CGFloat = 240
    private let spacing: CGFloat = 2
    private let cornerRadius: CGFloat = 12

    private var imageViews: [UIImageView] = []
    private let flexContainer = UIView()
    private var moreOverlay: UIView?

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
    }

    func configure(with imageURLs: [String]) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        moreOverlay?.removeFromSuperview()
        moreOverlay = nil
        flexContainer.subviews.forEach { $0.removeFromSuperview() }

        guard !imageURLs.isEmpty else { return }

        let displayCount = min(imageURLs.count, 5)
        for i in 0..<displayCount {
            let imageView = UIImageView().then {
                $0.contentMode = .scaleAspectFill
                $0.clipsToBounds = true
                $0.backgroundColor = ColorSystem.gray30
            }
            imageView.setImage(from: imageURLs[i])
            imageViews.append(imageView)
        }

        buildLayout()

        if imageURLs.count > 5 {
            addMoreIndicator(remainingCount: imageURLs.count - 5)
        }

        applyCornerRadius()
        setNeedsLayout()
    }

    private func buildLayout() {
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
            buildFiveImagesLayout()
        }
    }

    private func buildSingleImageLayout() {
        let height = Self.maxWidth * 0.75

        flexContainer.flex
            .direction(.column)
            .define { flex in
                flex.addItem(imageViews[0])
                    .width(Self.maxWidth)
                    .height(height)
            }
    }

    private func buildTwoImagesLayout() {
        let itemSize = (Self.maxWidth - spacing) / 2

        flexContainer.flex
            .direction(.row)
            .define { flex in
                flex.addItem(imageViews[0])
                    .width(itemSize)
                    .height(itemSize)
                flex.addItem(imageViews[1])
                    .width(itemSize)
                    .height(itemSize)
                    .marginLeft(spacing)
            }
    }

    private func buildThreeImagesLayout() {
        let leftWidth = (Self.maxWidth - spacing) / 2
        let rightWidth = (Self.maxWidth - spacing) / 2
        let totalHeight = Self.maxWidth
        let rightItemHeight = (totalHeight - spacing) / 2

        flexContainer.flex
            .direction(.row)
            .define { flex in
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
                    }
            }
    }

    private func buildFourImagesLayout() {
        let itemSize = (Self.maxWidth - spacing) / 2

        flexContainer.flex
            .direction(.column)
            .define { flex in
                flex.addItem()
                    .direction(.row)
                    .define { row in
                        row.addItem(imageViews[0])
                            .width(itemSize)
                            .height(itemSize)
                        row.addItem(imageViews[1])
                            .width(itemSize)
                            .height(itemSize)
                            .marginLeft(spacing)
                    }

                flex.addItem()
                    .direction(.row)
                    .marginTop(spacing)
                    .define { row in
                        row.addItem(imageViews[2])
                            .width(itemSize)
                            .height(itemSize)
                        row.addItem(imageViews[3])
                            .width(itemSize)
                            .height(itemSize)
                            .marginLeft(spacing)
                    }
            }
    }

    private func buildFiveImagesLayout() {
        let topItemWidth = (Self.maxWidth - spacing * 2) / 3
        let bottomItemWidth = (Self.maxWidth - spacing) / 2

        flexContainer.flex
            .direction(.column)
            .define { flex in
                flex.addItem()
                    .direction(.row)
                    .define { row in
                        row.addItem(imageViews[0])
                            .width(topItemWidth)
                            .height(topItemWidth)
                        row.addItem(imageViews[1])
                            .width(topItemWidth)
                            .height(topItemWidth)
                            .marginLeft(spacing)
                        row.addItem(imageViews[2])
                            .width(topItemWidth)
                            .height(topItemWidth)
                            .marginLeft(spacing)
                    }

                flex.addItem()
                    .direction(.row)
                    .marginTop(spacing)
                    .define { row in
                        row.addItem(imageViews[3])
                            .width(bottomItemWidth)
                            .height(bottomItemWidth)
                        row.addItem(imageViews[4])
                            .width(bottomItemWidth)
                            .height(bottomItemWidth)
                            .marginLeft(spacing)
                    }
            }
    }

    private func addMoreIndicator(remainingCount: Int) {
        guard let lastImageView = imageViews.last else { return }

        let overlay = UIView().then {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }

        let label = UILabel().then {
            $0.textColor = .white
            $0.textAlignment = .center
        }
        label.typography(FontSystem.Pretendard.title1Bold, text: "+\(remainingCount)")

        lastImageView.addSubview(overlay)
        overlay.addSubview(label)

        overlay.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: lastImageView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: lastImageView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: lastImageView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: lastImageView.bottomAnchor),

            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        moreOverlay = overlay
    }

    private func applyCornerRadius() {
        imageViews.forEach { $0.layer.cornerRadius = 0 }

        let count = imageViews.count
        guard count > 0 else { return }

        switch count {
        case 1:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]

        case 2:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            imageViews[1].layer.cornerRadius = cornerRadius
            imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        case 3:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            imageViews[1].layer.cornerRadius = cornerRadius
            imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
            imageViews[2].layer.cornerRadius = cornerRadius
            imageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]

        case 4:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]
            imageViews[1].layer.cornerRadius = cornerRadius
            imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
            imageViews[2].layer.cornerRadius = cornerRadius
            imageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
            imageViews[3].layer.cornerRadius = cornerRadius
            imageViews[3].layer.maskedCorners = [.layerMaxXMaxYCorner]

        default:
            imageViews[0].layer.cornerRadius = cornerRadius
            imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]
            imageViews[2].layer.cornerRadius = cornerRadius
            imageViews[2].layer.maskedCorners = [.layerMaxXMinYCorner]
            imageViews[3].layer.cornerRadius = cornerRadius
            imageViews[3].layer.maskedCorners = [.layerMinXMaxYCorner]
            imageViews[4].layer.cornerRadius = cornerRadius
            imageViews[4].layer.maskedCorners = [.layerMaxXMaxYCorner]
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        flexContainer.pin.all()
        flexContainer.flex.layout()
    }

    static func calculateSize(imageCount: Int) -> CGSize {
        guard imageCount > 0 else { return .zero }

        let spacing: CGFloat = 2

        switch imageCount {
        case 1:
            return CGSize(width: maxWidth, height: maxWidth * 0.75)
        case 2:
            let itemSize = (maxWidth - spacing) / 2
            return CGSize(width: maxWidth, height: itemSize)
        case 3, 4:
            return CGSize(width: maxWidth, height: maxWidth)
        default:
            let topHeight = (maxWidth - spacing * 2) / 3
            let bottomHeight = (maxWidth - spacing) / 2
            return CGSize(width: maxWidth, height: topHeight + spacing + bottomHeight)
        }
    }
}
