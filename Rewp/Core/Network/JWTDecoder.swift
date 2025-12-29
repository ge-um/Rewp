//
//  JWTDecoder.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation

enum JWTDecoder {
    static func extractExpiration(from token: String) -> Date? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }

        let payload = parts[1]
        guard let data = base64UrlDecode(payload) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }

        return Date(timeIntervalSince1970: exp)
    }

    private static func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64.append(contentsOf: repeatElement("=", count: paddingLength))
        }

        return Data(base64Encoded: base64)
    }
}
