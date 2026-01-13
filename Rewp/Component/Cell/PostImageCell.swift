//
//  PostImageCell.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit
import PinLayout
import Then
import Kingfisher

final class PostImageCell: UICollectionViewCell, IsIdentifiable {

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    private func setupUI() {
        contentView.addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.pin.all()
    }

    func configure(with imageURL: String, targetSize: CGSize) {
        imageView.setImage(from: imageURL, targetSize: targetSize)
    }
}
