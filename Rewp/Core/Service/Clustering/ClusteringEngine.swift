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
    private var clusterPointsCache: [String: [Int]] = [:]

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

    init(minZoom: Int = 0, maxZoom: Int = 16, radius: Int = 120, extent: Int = 256, nodeSize: Int = 64) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.radius = radius
        self.extent = extent
        self.nodeSize = nodeSize
    }

    func load(points: [T]) {
        let loadStart = CFAbsoluteTimeGetCurrent()
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
                zoom: maxZoom + 1
            )
        }
        Logger.map.debug("Initial clusters created: \(clusters.count) (zoom: \(self.maxZoom + 1))")

        var treeStart = CFAbsoluteTimeGetCurrent()
        trees[maxZoom + 1] = KDBush(points: clusters, nodeSize: nodeSize)
        var treeTime = CFAbsoluteTimeGetCurrent() - treeStart
        Logger.map.notice("Tree zoom \(self.maxZoom + 1): \(String(format: "%.3f", treeTime))s (\(clusters.count) points)")

        for zoom in stride(from: maxZoom, through: minZoom, by: -1) {
            let beforeCount = clusters.count

            let clusterStart = CFAbsoluteTimeGetCurrent()
            clusters = buildClustersForZoomLevel(clusters: clusters, zoom: zoom)
            let clusterTime = CFAbsoluteTimeGetCurrent() - clusterStart

            treeStart = CFAbsoluteTimeGetCurrent()
            trees[zoom] = KDBush(points: clusters, nodeSize: nodeSize)
            treeTime = CFAbsoluteTimeGetCurrent() - treeStart

            Logger.map.notice("Zoom \(zoom): cluster \(String(format: "%.3f", clusterTime))s, tree \(String(format: "%.3f", treeTime))s (\(beforeCount) → \(clusters.count))")
        }

        let totalTime = CFAbsoluteTimeGetCurrent() - loadStart
        Logger.map.notice("=== Clustering COMPLETE: \(String(format: "%.3f", totalTime))s total, \(self.trees.count) zoom levels ===")
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
            let clusterId = c.isCluster ? "cluster_\(c.zoom)_\(id)" : "single_\(c.zoom)_\(id)"

            let leafIndices = getLeafIndices(for: clusterId, cluster: c, treeIndex: id)
            let childPoints = leafIndices.map { points[$0] }

            let cluster = Cluster(
                id: clusterId,
                latitude: c.latitude,
                longitude: c.longitude,
                points: childPoints,
                actualCount: c.numPoints
            )
            results.append(cluster)
            Logger.map.debug("  [getClusters] Point[\(id)] → cluster with \(c.numPoints) points (childPoints: \(childPoints.count))")
        }

        Logger.map.notice("Result: \(results.count) total clusters")
        return results
    }

    private func getLeafIndices(for clusterId: String, cluster: ClusterOrPoint, treeIndex: Int) -> [Int] {
        if let cached = clusterPointsCache[clusterId] {
            return cached
        }

        if let originalIndex = cluster.originalIndex {
            clusterPointsCache[clusterId] = [originalIndex]
            return [originalIndex]
        }

        guard let parentTree = trees[cluster.zoom + 1] else {
            return []
        }

        let r = Double(radius) / (Double(extent) * pow(2.0, Double(cluster.zoom)))
        let x = longitudeToX(cluster.longitude)
        let y = latitudeToY(cluster.latitude)
        let neighborIds = parentTree.within(x: x, y: y, radius: r)

        var leafIndicesSet: Set<Int> = []
        leafIndicesSet.reserveCapacity(cluster.numPoints)

        for neighborId in neighborIds {
            let neighbor = parentTree.points[neighborId]
            if neighbor.zoom <= cluster.zoom { continue }

            let neighborClusterId = "cluster_\(neighbor.zoom)_\(neighborId)"
            let neighborLeaves = getLeafIndices(for: neighborClusterId, cluster: neighbor, treeIndex: neighborId)
            leafIndicesSet.formUnion(neighborLeaves)
        }

        let result = Array(leafIndicesSet)
        clusterPointsCache[clusterId] = result
        return result
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
}

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
