//
//  UIImage+Resize.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        return renderer.image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: radians)
            self.draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }
}
