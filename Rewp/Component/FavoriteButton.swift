//
//  FavoriteButton.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import UIKit
import Then

final class FavoriteButton: UIButton {
    private(set) var isFavorite: Bool = false

    init(filled: Bool = false) {
        self.isFavorite = filled
        super.init(frame: .zero)
        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButton() {
        let imageName = isFavorite ? "Like_Fill" : "Like_Empty"
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        setImage(image, for: .normal)
        tintColor = ColorSystem.gray60
        backgroundColor = .red
        layer.borderColor = ColorSystem.gray30.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
        imageView?.contentMode = .center
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
    }

    func toggle() {
        isFavorite.toggle()
        let imageName = isFavorite ? "Like_Fill" : "Like_Empty"
        setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    func setFavorite(_ filled: Bool) {
        isFavorite = filled
        let imageName = filled ? "Like_Fill" : "Like_Empty"
        setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 48, height: 48)
    }
}
