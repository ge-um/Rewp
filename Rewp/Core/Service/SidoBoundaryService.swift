//
//  SidoBoundaryService.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import Foundation
import MapKit
import OSLog

final class SidoBoundaryService {
    static let shared = SidoBoundaryService()

    private var sidoList: [Sido] = []
    private var isLoaded = false

    private init() {
        loadBoundaries()
    }

    var allSidos: [Sido] {
        return sidoList
    }

    func loadBoundaries() {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: "sido_boundaries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else {
            Logger.map.error("Failed to load sido_boundaries.geojson")
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            Logger.map.error("Failed to parse sido_boundaries.geojson")
            return
        }

        sidoList = features.compactMap { feature -> Sido? in
            guard let properties = feature["properties"] as? [String: Any],
                  let code = properties["code"] as? String,
                  let name = properties["name"] as? String,
                  let centerArray = properties["center"] as? [Double],
                  centerArray.count >= 2,
                  let geometry = feature["geometry"] as? [String: Any],
                  let geometryType = geometry["type"] as? String else {
                return nil
            }

            let center = CLLocationCoordinate2D(
                latitude: centerArray[1],
                longitude: centerArray[0]
            )

            var allCoordinates: [[CLLocationCoordinate2D]] = []

            if geometryType == "Polygon",
               let coordinates = geometry["coordinates"] as? [[[Double]]] {
                let points = coordinates[0]
                let clCoordinates = points.map {
                    CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                }
                allCoordinates.append(clCoordinates)
            } else if geometryType == "MultiPolygon",
                      let multiCoordinates = geometry["coordinates"] as? [[[[Double]]]] {
                for polygon in multiCoordinates {
                    let points = polygon[0]
                    let clCoordinates = points.map {
                        CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                    }
                    allCoordinates.append(clCoordinates)
                }
            }

            guard !allCoordinates.isEmpty else { return nil }

            let polygon = MKPolygon(coordinates: allCoordinates[0], count: allCoordinates[0].count)
            polygon.title = name

            var minLon = Double.greatestFiniteMagnitude
            var maxLon = -Double.greatestFiniteMagnitude
            var minLat = Double.greatestFiniteMagnitude
            var maxLat = -Double.greatestFiniteMagnitude

            for coords in allCoordinates {
                for coord in coords {
                    minLon = min(minLon, coord.longitude)
                    maxLon = max(maxLon, coord.longitude)
                    minLat = min(minLat, coord.latitude)
                    maxLat = max(maxLat, coord.latitude)
                }
            }

            return Sido(
                code: code,
                name: name,
                nameEn: name,
                center: center,
                boundingBox: (minLon, minLat, maxLon, maxLat),
                polygon: polygon
            )
        }

        isLoaded = true
        Logger.map.notice("Loaded \(self.sidoList.count) sido boundaries")
    }

    func findSido(for coordinate: CLLocationCoordinate2D) -> Sido? {
        for sido in sidoList {
            let bbox = sido.boundingBox
            if coordinate.longitude >= bbox.minLon &&
               coordinate.longitude <= bbox.maxLon &&
               coordinate.latitude >= bbox.minLat &&
               coordinate.latitude <= bbox.maxLat {
                if sido.contains(coordinate: coordinate) {
                    return sido
                }
            }
        }
        return nil
    }

    func countEstates(estates: [EstateDTO]) -> [String: (sido: Sido, count: Int)] {
        var counts: [String: (sido: Sido, count: Int)] = [:]

        for sido in sidoList {
            counts[sido.code] = (sido: sido, count: 0)
        }

        for estate in estates {
            let coordinate = CLLocationCoordinate2D(
                latitude: estate.latitude,
                longitude: estate.longitude
            )

            if let sido = findSido(for: coordinate) {
                if var current = counts[sido.code] {
                    current.count += 1
                    counts[sido.code] = current
                }
            }
        }

        return counts
    }
}
