//
//  FontSystem.swift
//  Rewp
//
//  Created by 금가경 on 12/25/25.
//

import UIKit

struct Typography {
    let font: UIFont
    let size: CGFloat
    let lineHeightPercentage: CGFloat
    let kerning: CGFloat

    var lineHeight: CGFloat {
        return size * (lineHeightPercentage / 100.0)
    }

    init(fontName: String, size: CGFloat, lineHeight: CGFloat, kerning: CGFloat) {
        self.font = UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size)
        self.size = size
        self.lineHeightPercentage = lineHeight
        self.kerning = kerning
    }
}

enum FontSystem {
    enum Pretendard {
        static let title0 = Typography(
            fontName: "Pretendard-Bold",
            size: 30,
            lineHeight: 100,
            kerning: 0
        )
        static let title1 = Typography(
            fontName: "Pretendard-Bold",
            size: 22,
            lineHeight: 130,
            kerning: 0
        )

        static let body1 = Typography(
            fontName: "Pretendard-Bold",
            size: 16,
            lineHeight: 130,
            kerning: 0
        )

        static let body2 = Typography(
            fontName: "Pretendard-Medium",
            size: 14,
            lineHeight: 130,
            kerning: 0
        )
        
        static let body2Bold = Typography(
            fontName: "Pretendard-Bold",
            size: 14,
            lineHeight: 130,
            kerning: 0
        )

        static let body3 = Typography(
            fontName: "Pretendard-Medium",
            size: 13,
            lineHeight: 130,
            kerning: 0
        )

        static let caption1Semibold = Typography(
            fontName: "Pretendard-Semibold",
            size: 12,
            lineHeight: 130,
            kerning: 0
        )
        
        static let caption1Regular = Typography(
            fontName: "Pretendard-Regular",
            size: 12,
            lineHeight: 170,
            kerning: 0
        )

        static let caption2 = Typography(
            fontName: "Pretendard-Regular",
            size: 10,
            lineHeight: 130,
            kerning: 0
        )

        static let caption3 = Typography(
            fontName: "Pretendard-Regular",
            size: 8,
            lineHeight: 130,
            kerning: 0
        )
    }

    enum YeongdeokHaeparang {
        static let title1 = Typography(
            fontName: "Yeongdeok-Haeparang",
            size: 22,
            lineHeight: 150,
            kerning: 0
        )

        static let caption1 = Typography(
            fontName: "Yeongdeok-Haeparang",
            size: 12,
            lineHeight: 180,
            kerning: 0
        )
    }
}

extension UILabel {
    func typography(_ typography: Typography, text: String? = nil) {
        if let text = text ?? self.text {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = typography.lineHeight
            paragraphStyle.maximumLineHeight = typography.lineHeight
            paragraphStyle.alignment = self.textAlignment

            self.attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .font: typography.font,
                    .kern: typography.kerning,
                    .paragraphStyle: paragraphStyle
                ]
            )
        }
    }
}

extension String {
    func typography(_ typography: Typography, alignment: NSTextAlignment = .left) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = typography.lineHeight
        paragraphStyle.maximumLineHeight = typography.lineHeight
        paragraphStyle.alignment = alignment

        return NSAttributedString(
            string: self,
            attributes: [
                .font: typography.font,
                .kern: typography.kerning,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}

extension UITextField {
    func typography(_ typography: Typography, placeholder: String? = nil, placeholderColor: UIColor = ColorSystem.gray45) {
        self.font = typography.font
        self.defaultTextAttributes = [
            .font: typography.font,
            .kern: typography.kerning
        ]

        if let placeholder = placeholder ?? self.placeholder {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = typography.lineHeight
            paragraphStyle.maximumLineHeight = typography.lineHeight

            self.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .font: typography.font,
                    .kern: typography.kerning,
                    .foregroundColor: placeholderColor,
                    .paragraphStyle: paragraphStyle
                ]
            )
        }
    }
}
