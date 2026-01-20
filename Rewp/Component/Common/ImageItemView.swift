//
//  ImageItemView.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit
import PinLayout

final class ImageItemView: UIView {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }

    private lazy var deleteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.gray90.withAlphaComponent(0.8)
        config.baseForegroundColor = ColorSystem.gray0
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        config.image = UIImage(systemName: "xmark")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        )

        let button = UIButton(configuration: config)
        return button
    }()

    private var onDeleteAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(imageView)
        addSubview(deleteButton)

        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    @objc private func deleteButtonTapped() {
        onDeleteAction?()
    }

    func configure(image: UIImage, onDelete: @escaping () -> Void) {
        imageView.image = image
        onDeleteAction = onDelete
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.pin
            .all()

        deleteButton.pin
            .top(4)
            .right(4)
            .size(20)
    }
}
