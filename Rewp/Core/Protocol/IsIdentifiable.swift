//
//  IsIdentifiable.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation

protocol IsIdentifiable {
    static var identifier: String { get }
}

extension IsIdentifiable {
    static var identifier: String {
        return String(describing: Self.self)
    }
}
