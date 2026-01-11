//
//  ManwonFormatter.swift
//  Rewp
//
//  Created by 금가경 on 01/11/26.
//

import Foundation

extension Int {
    func formatAsManwon() -> String {
        let eok = self / 10000
        let manwon = self % 10000

        if eok > 0 && manwon > 0 {
            return "\(eok)억 \(manwon)만원"
        } else if eok > 0 {
            return "\(eok)억"
        } else {
            return "\(manwon)만원"
        }
    }

    func formatAsManwonCompact() -> String {
        let eok = self / 10000
        let manwon = self % 10000

        if eok > 0 && manwon > 0 {
            let decimal = Double(manwon) / 10000.0
            let total = Double(eok) + decimal
            return String(format: "%.1f억", total)
        } else if eok > 0 {
            return "\(eok)억"
        } else {
            return "\(manwon)만원"
        }
    }
}
