//
//  MockPoint.swift
//  RewpTests
//
//  Created by 금가경 on 01/20/26.
//

@testable import Rewp

struct MockPoint: ClusterPoint {
    let latitude: Double
    let longitude: Double
}

extension MockPoint {
    static func generate(count: Int) -> [MockPoint] {
        (0..<count).map { _ in
            MockPoint(
                latitude: Double.random(in: 33.0...38.0),
                longitude: Double.random(in: 125.0...132.0)
            )
        }
    }
}
