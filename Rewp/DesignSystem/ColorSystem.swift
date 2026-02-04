//
//  ColorSystem.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit

enum ColorSystem {
    static let deepCream = UIColor(hex: "#567DF3")
    static let brightCream = UIColor(hex: "#F1DCC1")
    static let deepCoast = UIColor(hex: "#298E9C")
    static let brightCoast = UIColor(hex: "#8BADFF")
    static let deepWood = UIColor(hex: "#0F2D8E")
    static let brightWood = UIColor(hex: "#2B63E6")

    static let gray0 = UIColor(hex: "#FFFFFF")
    static let gray15 = UIColor(hex: "#F9F9F9")
    static let gray30 = UIColor(hex: "#EAEAEA")
    static let gray45 = UIColor(hex: "#D8D6D7")
    static let gray60 = UIColor(hex: "#ABABAE")
    static let gray75 = UIColor(hex: "#6A6A6E")
    static let gray90 = UIColor(hex: "#434347")
    static let gray100 = UIColor(hex: "#000000")
    
    static let shadow = UIColor(hex: "#7B7886")
    
    static let kakaoYellow = UIColor(hex: "#FEE500")
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        hexFormatted = hexFormatted.replacingOccurrences(of: "#", with: "")

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
