//
//  ChatImageGridView.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import FlexLayout
import Then
import Kingfisher

final class ChatImageGridView: UIView {
    static let imageSize: CGFloat = 80
    static let spacing: CGFloat = 4

    private var imageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with imageURLs: [String]) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        guard !imageURLs.isEmpty else {
            return
        }

        for urlString in imageURLs {
            let imageView = UIImageView().then {
                $0.contentMode = .scaleAspectFill
                $0.clipsToBounds = true
                $0.layer.cornerRadius = 8
                $0.backgroundColor = ColorSystem.gray30
            }

            imageView.setImage(from: urlString)
            imageViews.append(imageView)
        }

        flex
            .direction(.column)
            .define { flex in
                var currentRow: Flex?

                for (index, imageView) in imageViews.enumerated() {
                    if index % 2 == 0 {
                        currentRow = flex.addItem()
                            .direction(.row)

                        if index > 0 {
                            currentRow?.marginTop(Self.spacing)
                        }
                    }

                    if index % 2 == 0 {
                        currentRow?.addItem(imageView)
                            .width(Self.imageSize)
                            .height(Self.imageSize)
                    } else {
                        currentRow?.addItem(imageView)
                            .width(Self.imageSize)
                            .height(Self.imageSize)
                            .marginLeft(Self.spacing)
                    }
                }
            }
    }

    static func calculateSize(imageCount: Int) -> CGSize {
        guard imageCount > 0 else {
            return .zero
        }

        let rowCount = (imageCount + 1) / 2
        let colCount = min(imageCount, 2)

        let width = CGFloat(colCount) * imageSize + CGFloat(colCount - 1) * spacing
        let height = CGFloat(rowCount) * imageSize + CGFloat(max(0, rowCount - 1)) * spacing

        return CGSize(width: width, height: height)
    }
}
