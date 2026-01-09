//
//  ClusteringEngine.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation
import OSLog

final class ClusteringEngine<T: ClusterPoint> {
    private let minZoom: Int
    private let maxZoom: Int
    private let radius: Int
    private let extent: Int
    private let nodeSize: Int

    private var trees: [Int: KDBush<ClusterOrPoint>] = [:]
    private var points: [T] = []

    struct ClusterOrPoint: ClusterPoint {
        let latitude: Double
        let longitude: Double
        let originalIndex: Int?
        let parentId: Int?
        let numPoints: Int
        let zoom: Int

        var isCluster: Bool {
            return numPoints > 1
        }
    }

    init(minZoom: Int = 0, maxZoom: Int = 16, radius: Int = 80, extent: Int = 256, nodeSize: Int = 64) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.radius = radius
        self.extent = extent
        self.nodeSize = nodeSize
    }

    func load(points: [T]) {
        self.points = points

        Logger.map.notice("=== Clustering START: \(points.count) points ===")
        Logger.map.debug("Zoom range: \(self.minZoom)...\(self.maxZoom), radius: \(self.radius), extent: \(self.extent)")

        var clusters: [ClusterOrPoint] = points.enumerated().map { index, point in
            ClusterOrPoint(
                latitude: point.latitude,
                longitude: point.longitude,
                originalIndex: index,
                parentId: nil,
                numPoints: 1,
                zoom: maxZoom
            )
        }
        Logger.map.debug("Initial clusters created: \(clusters.count) (zoom: \(self.maxZoom))")

        trees[maxZoom] = KDBush(points: clusters, nodeSize: nodeSize)
        Logger.map.notice("--- Building tree for zoom \(self.maxZoom) with \(clusters.count) clusters (no clustering) ---")

        for zoom in stride(from: maxZoom - 1, through: minZoom, by: -1) {
            let beforeCount = clusters.count
            clusters = buildClustersForZoomLevel(clusters: clusters, zoom: zoom)
            Logger.map.notice("Clustering zoom \(zoom): \(beforeCount) → \(clusters.count) clusters (reduced by \(beforeCount - clusters.count))")

            trees[zoom] = KDBush(points: clusters, nodeSize: nodeSize)
            Logger.map.debug("Tree created for zoom \(zoom)")
        }

        Logger.map.notice("=== Clustering COMPLETE: \(self.trees.count) zoom levels ===")
    }

    func getClusters(bbox: (minLon: Double, minLat: Double, maxLon: Double, maxLat: Double), zoom: Int) -> [Cluster<T>] {
        Logger.map.notice("=== getClusters: zoom \(zoom) ===")
        let adjustedZoom = min(max(zoom, minZoom), maxZoom)
        if adjustedZoom != zoom {
            Logger.map.debug("Zoom adjusted: \(zoom) → \(adjustedZoom)")
        }

        let minX = longitudeToX(bbox.minLon)
        let minY = latitudeToY(bbox.maxLat)
        let maxX = longitudeToX(bbox.maxLon)
        let maxY = latitudeToY(bbox.minLat)
        Logger.map.debug("BBox: lon[\(bbox.minLon, privacy: .public)...\(bbox.maxLon, privacy: .public)] lat[\(bbox.minLat, privacy: .public)...\(bbox.maxLat, privacy: .public)]")
        Logger.map.debug("Normalized: x[\(minX, privacy: .public)...\(maxX, privacy: .public)] y[\(minY, privacy: .public)...\(maxY, privacy: .public)]")

        guard let tree = trees[adjustedZoom] else {
            Logger.map.error("No tree found for zoom \(adjustedZoom)")
            return []
        }

        let ids = tree.range(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
        Logger.map.debug("Tree range search found \(ids.count) candidate points")

        var results: [Cluster<T>] = []

        for id in ids {
            let c = tree.points[id]
            let childPoints = collectLeafPoints(from: c)

            let cluster = Cluster(
                id: c.isCluster ? "cluster_\(c.zoom)_\(id)" : "single_\(c.zoom)_\(id)",
                latitude: c.latitude,
                longitude: c.longitude,
                points: childPoints,
                expansionZoom: c.isCluster ? calculateExpansionZoomLevel(for: id, at: adjustedZoom) : nil,
                actualCount: c.numPoints
            )
            results.append(cluster)
            Logger.map.debug("  [getClusters] Point[\(id)] → cluster with \(c.numPoints) points (childPoints: \(childPoints.count))")
        }

        Logger.map.notice("Result: \(results.count) total clusters")
        return results
    }

    private func buildClustersForZoomLevel(clusters: [ClusterOrPoint], zoom: Int) -> [ClusterOrPoint] {
        Logger.map.debug("  [cluster] Starting clustering at zoom \(zoom)")
        var nextClusters: [ClusterOrPoint] = []
        var visited = Array(repeating: false, count: clusters.count)
        let r = Double(radius) / (Double(extent) * pow(2.0, Double(zoom)))
        Logger.map.debug("  [cluster] Cluster radius: \(r, privacy: .public)")

        var mergedCount = 0
        var singleCount = 0

        for i in 0..<clusters.count {
            let c = clusters[i]

            if c.zoom <= zoom {
                Logger.map.debug("  [cluster] Skip point[\(i)]: zoom \(c.zoom) <= \(zoom)")
                continue
            }
            if visited[i] {
                Logger.map.debug("  [cluster] Skip point[\(i)]: already visited")
                continue
            }

            guard let tree = trees[zoom + 1] else {
                Logger.map.error("  [cluster] No tree for zoom \(zoom + 1)")
                continue
            }
            let x = longitudeToX(c.longitude)
            let y = latitudeToY(c.latitude)

            let neighborIds = tree.within(x: x, y: y, radius: r)
            Logger.map.debug("  [cluster] Point[\(i)] found \(neighborIds.count) neighbors (including self)")

            var numPoints = c.numPoints
            var wx = c.longitude * Double(c.numPoints)
            var wy = c.latitude * Double(c.numPoints)

            visited[i] = true
            var mergedNeighbors = 0

            for neighborId in neighborIds {
                if visited[neighborId] { continue }

                let b = tree.points[neighborId]

                if b.zoom <= zoom { continue }

                visited[neighborId] = true
                numPoints += b.numPoints
                wx += b.longitude * Double(b.numPoints)
                wy += b.latitude * Double(b.numPoints)
                mergedNeighbors += 1
            }

            if mergedNeighbors > 0 {
                Logger.map.debug("  [cluster] Point[\(i)] merged with \(mergedNeighbors) neighbors → total \(numPoints) points")
                mergedCount += 1
            } else {
                Logger.map.debug("  [cluster] Point[\(i)] stays single with \(numPoints) points")
                singleCount += 1
            }

            let newCluster = ClusterOrPoint(
                latitude: wy / Double(numPoints),
                longitude: wx / Double(numPoints),
                originalIndex: numPoints == 1 ? c.originalIndex : nil,
                parentId: i,
                numPoints: numPoints,
                zoom: zoom
            )

            nextClusters.append(newCluster)
        }

        Logger.map.debug("  [cluster] Result: \(mergedCount) merged clusters, \(singleCount) single points → \(nextClusters.count) total")
        return nextClusters
    }

    private func collectLeafPoints(from cluster: ClusterOrPoint) -> [T] {
        var result: [T] = []

        func collectPoints(_ c: ClusterOrPoint) {
            if let originalIndex = c.originalIndex {
                result.append(points[originalIndex])
            } else if let parentId = c.parentId, let tree = trees[c.zoom + 1] {
                let parent = tree.points[parentId]
                collectPoints(parent)
            }
        }

        collectPoints(cluster)
        return result
    }

    private func calculateExpansionZoomLevel(for clusterId: Int, at zoom: Int) -> Int? {
        var expansionZoom = zoom
        while expansionZoom < maxZoom {
            guard let tree = trees[expansionZoom] else { return nil }
            let cluster = tree.points[clusterId]

            let r = Double(radius) / (Double(extent) * pow(2.0, Double(expansionZoom)))
            let x = longitudeToX(cluster.longitude)
            let y = latitudeToY(cluster.latitude)

            let neighborIds = tree.within(x: x, y: y, radius: r)

            if neighborIds.count <= 1 {
                break
            }

            expansionZoom += 1
        }

        return expansionZoom
    }
}

// MARK: - Coordinate Transformation Utilities

private extension ClusteringEngine {
    /// 경도를 정규화된 X 좌표로 변환 (0.0 ~ 1.0)
    func longitudeToX(_ longitude: Double) -> Double {
        return longitude / 360.0 + 0.5
    }

    /// 위도를 정규화된 Y 좌표로 변환 (Web Mercator 투영)
    func latitudeToY(_ latitude: Double) -> Double {
        let sin = sin(latitude * .pi / 180)
        let y = 0.5 - 0.25 * log((1 + sin) / (1 - sin)) / .pi
        return y < 0 ? 0 : y > 1 ? 1 : y
    }
}
