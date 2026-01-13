//
//  UIView+Shadow.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit

enum ShadowStyle {
    case topBar

    var color: UIColor {
        switch self {
        case .topBar:
            return ColorSystem.gray100
        }
    }

    var opacity: Float {
        switch self {
        case .topBar:
            return 0.04
        }
    }

    var offset: CGSize {
        switch self {
        case .topBar:
            return CGSize(width: 0, height: -1)
        }
    }

    var radius: CGFloat {
        switch self {
        case .topBar:
            return 1
        }
    }
}

extension UIView {
    func applyShadow(_ style: ShadowStyle) {
        layer.shadowColor = style.color.cgColor
        layer.shadowOpacity = style.opacity
        layer.shadowOffset = style.offset
        layer.shadowRadius = style.radius
    }
}
