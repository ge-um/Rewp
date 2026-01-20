//
//  ClusteringEnginePerformanceTests.swift
//  RewpTests
//
//  Created by 금가경 on 01/19/26.
//

import XCTest
@testable import Rewp

struct EstateResponse: Codable {
    let data: [EstateDTO]
}

// MARK: - MockPoint 테스트 (경량 데이터)

final class ClusteringEngineMockPointTests: XCTestCase {
    private var points1000: [MockPoint]!
    private var points5000: [MockPoint]!
    private var points10000: [MockPoint]!
    private var bbox: (minLon: Double, minLat: Double, maxLon: Double, maxLat: Double)!

    override func setUp() {
        super.setUp()
        points1000 = MockPoint.generate(count: 1_000)
        points5000 = MockPoint.generate(count: 5_000)
        points10000 = MockPoint.generate(count: 10_000)
        bbox = (minLon: 126.5, minLat: 37.0, maxLon: 127.5, maxLat: 38.0)
    }

    override func tearDown() {
        points1000 = nil
        points5000 = nil
        points10000 = nil
        bbox = nil
        super.tearDown()
    }

    // MARK: - load() Performance

    func testLoad1000Points() {
        let points = points1000!
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
            engine.load(points: points)
        }
    }

    func testLoad5000Points() {
        let points = points5000!
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
            engine.load(points: points)
        }
    }

    func testLoad10000Points() {
        let points = points10000!
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
            engine.load(points: points)
        }
    }

    // MARK: - getClusters() Performance at Zoom 7

    func testGetClustersZoom7With1000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points1000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 7)
        }
    }

    func testGetClustersZoom7With5000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points5000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 7)
        }
    }

    func testGetClustersZoom7With10000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points10000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 7)
        }
    }

    // MARK: - getClusters() Performance at Zoom 12

    func testGetClustersZoom12With1000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points1000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 12)
        }
    }

    func testGetClustersZoom12With5000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points5000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 12)
        }
    }

    func testGetClustersZoom12With10000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points10000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 12)
        }
    }

    // MARK: - getClusters() Performance at Zoom 16

    func testGetClustersZoom16With1000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points1000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 16)
        }
    }

    func testGetClustersZoom16With5000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points5000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 16)
        }
    }

    func testGetClustersZoom16With10000Points() {
        let engine = ClusteringEngine<MockPoint>(minZoom: 7, maxZoom: 16)
        engine.load(points: points10000)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 16)
        }
    }
}

// MARK: - 실제 EstateDTO 테스트 (JSON 데이터)

final class ClusteringEnginePerformanceTests: XCTestCase {
    private var realEstates: [EstateDTO]!
    private var doubledEstates: [EstateDTO]!
    private var bbox: (minLon: Double, minLat: Double, maxLon: Double, maxLat: Double)!

    override func setUp() {
        super.setUp()
        realEstates = loadEstatesFromJSON()
        doubledEstates = realEstates + realEstates
        bbox = (minLon: 126.5, minLat: 37.0, maxLon: 127.5, maxLat: 38.0)
    }

    override func tearDown() {
        realEstates = nil
        doubledEstates = nil
        bbox = nil
        super.tearDown()
    }

    private func loadEstatesFromJSON() -> [EstateDTO] {
        guard let url = Bundle(for: type(of: self)).url(forResource: "Estate", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(EstateResponse.self, from: data) else {
            fatalError("Estate.json 로드 실패")
        }
        return response.data
    }

    // MARK: - load() Performance (실제 데이터 ~5000개)

    func testLoadRealEstates() {
        let estates = realEstates!
        print("실제 데이터 개수: \(estates.count)")
        measure(metrics: [XCTClockMetric()]) {
            let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
            engine.load(points: estates)
        }
    }

    // MARK: - load() Performance (실제 데이터 x2 ~10000개)

    func testLoadDoubledEstates() {
        let estates = doubledEstates!
        print("두 배 데이터 개수: \(estates.count)")
        measure(metrics: [XCTClockMetric()]) {
            let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
            engine.load(points: estates)
        }
    }

    // MARK: - getClusters() Performance

    func testGetClustersZoom7WithRealEstates() {
        let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
        engine.load(points: realEstates)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 7)
        }
    }

    func testGetClustersZoom7WithDoubledEstates() {
        let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
        engine.load(points: doubledEstates)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 7)
        }
    }

    func testGetClustersZoom12WithRealEstates() {
        let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
        engine.load(points: realEstates)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 12)
        }
    }

    func testGetClustersZoom12WithDoubledEstates() {
        let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
        engine.load(points: doubledEstates)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 12)
        }
    }

    func testGetClustersZoom16WithRealEstates() {
        let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
        engine.load(points: realEstates)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 16)
        }
    }

    func testGetClustersZoom16WithDoubledEstates() {
        let engine = ClusteringEngine<EstateDTO>(minZoom: 7, maxZoom: 16)
        engine.load(points: doubledEstates)
        let bbox = self.bbox!

        measure(metrics: [XCTClockMetric()]) {
            _ = engine.getClusters(bbox: bbox, zoom: 16)
        }
    }
}
