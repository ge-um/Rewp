//
//  ShadowSystem.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit

struct Shadow {
    let color: UIColor
    let opacity: Float
    let offset: CGSize
    let radius: CGFloat
}

enum ShadowSystem {
    static let xs = Shadow(
        color: ColorSystem.gray100,
        opacity: 0.04,
        offset: CGSize(width: 0, height: -1),
        radius: 1
    )

    static let sm = Shadow(
        color: ColorSystem.shadow,
        opacity: 0.08,
        offset: CGSize(width: 0, height: 4),
        radius: 6
    )

    static let smTop = Shadow(
        color: ColorSystem.shadow,
        opacity: 0.08,
        offset: CGSize(width: 0, height: -2),
        radius: 6
    )

    static let md = Shadow(
        color: .black,
        opacity: 0.1,
        offset: CGSize(width: 0, height: 2),
        radius: 4
    )

    static let mdEmphasis = Shadow(
        color: ColorSystem.shadow,
        opacity: 0.15,
        offset: CGSize(width: 0, height: 2),
        radius: 4
    )

    static let lg = Shadow(
        color: .black,
        opacity: 0.1,
        offset: CGSize(width: 0, height: 2),
        radius: 8
    )

    static let xl = Shadow(
        color: .black,
        opacity: 0.15,
        offset: CGSize(width: 0, height: 4),
        radius: 12
    )

    static let none = Shadow(
        color: .clear,
        opacity: 0,
        offset: .zero,
        radius: 0
    )
}

extension CALayer {
    func applyShadow(_ shadow: Shadow) {
        shadowColor = shadow.color.cgColor
        shadowOpacity = shadow.opacity
        shadowOffset = shadow.offset
        shadowRadius = shadow.radius
    }
}

extension UIView {
    func applyShadow(_ shadow: Shadow) {
        layer.applyShadow(shadow)
    }
}
