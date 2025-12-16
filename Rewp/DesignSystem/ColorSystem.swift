import UIKit

enum ColorSystem {
    static let deepCream = UIColor(hex: "#D4C8B1")
    static let brightCream = UIColor(hex: "#F1DCC1")
    static let deepCoast = UIColor(hex: "#298E9C")
    static let brightCoast = UIColor(hex: "#71C9D6")
    static let deepWood = UIColor(hex: "#402A32")
    static let brightWood = UIColor(hex: "#8C5543")

    static let gray0 = UIColor(hex: "#FFFFFF")
    static let gray15 = UIColor(hex: "#D9D9D9")
    static let gray30 = UIColor(hex: "#B3B3B3")
    static let gray45 = UIColor(hex: "#8C8C8C")
    static let gray60 = UIColor(hex: "#666666")
    static let gray75 = UIColor(hex: "#404040")
    static let gray90 = UIColor(hex: "#1A1A1A")
    static let gray100 = UIColor(hex: "#000000")
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
