//
//  KDBush.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation
import OSLog

final class KDBush<T: ClusterPoint> {
    let points: [T]
    private var ids: [Int] = []
    private var coords: [Double] = []
    private let nodeSize: Int

    init(points: [T], nodeSize: Int = 64) {
        self.points = points
        self.nodeSize = nodeSize
        self.ids = Array(0..<points.count)
        self.coords = Array(repeating: 0.0, count: points.count * 2)

        Logger.map.debug("    [KDBush] Initializing with \(points.count) points, nodeSize: \(nodeSize)")

        for i in 0..<points.count {
            coords[2 * i] = longitudeToX(points[i].longitude)
            coords[2 * i + 1] = latitudeToY(points[i].latitude)
        }
        Logger.map.debug("    [KDBush] Coordinates converted to normalized space")

        Logger.map.debug("    [KDBush] Starting KD-tree construction (sortKD)")
        sortKD(left: 0, right: points.count - 1, axis: 0, depth: 0)
        Logger.map.debug("    [KDBush] KD-tree construction complete")
    }

    func range(minX: Double, minY: Double, maxX: Double, maxY: Double) -> [Int] {
        var result: [Int] = []
        rangeSearch(
            nodeIndex: 0,
            left: 0,
            right: points.count - 1,
            minX: minX,
            minY: minY,
            maxX: maxX,
            maxY: maxY,
            result: &result
        )
        return result
    }

    func within(x: Double, y: Double, radius: Double) -> [Int] {
        Logger.map.debug("        [within] Searching neighbors at (\(x, privacy: .public), \(y, privacy: .public)) with radius \(radius, privacy: .public)")
        var result: [Int] = []
        let r2 = radius * radius
        withinSearch(
            nodeIndex: 0,
            left: 0,
            right: points.count - 1,
            x: x,
            y: y,
            r2: r2,
            result: &result
        )
        Logger.map.debug("        [within] Found \(result.count) neighbors: \(result)")
        return result
    }

    private func sortKD(left: Int, right: Int, axis: Int, depth: Int) {
        let range = right - left + 1
        if range <= nodeSize {
            Logger.map.debug("      [sortKD] Leaf node at depth \(depth): range [\(left)...\(right)] = \(range) points (≤ nodeSize \(self.nodeSize))")
            return
        }

        let mid = (left + right) >> 1
        let axisName = axis == 0 ? "X (longitude)" : "Y (latitude)"
        Logger.map.debug("      [sortKD] Depth \(depth), axis: \(axisName), range [\(left)...\(right)] = \(range) points → splitting at mid \(mid)")

        select(k: mid, left: left, right: right, axis: axis)
        Logger.map.debug("      [sortKD] Partition complete at mid \(mid)")

        sortKD(left: left, right: mid - 1, axis: 1 - axis, depth: depth + 1)
        sortKD(left: mid + 1, right: right, axis: 1 - axis, depth: depth + 1)
    }

    private func select(k: Int, left: Int, right: Int, axis: Int) {
        var left = left
        var right = right

        while right > left {
            if right - left > 600 {
                let n = Double(right - left + 1)
                let m = Double(k - left + 1)
                let z = log(n)
                let s = 0.5 * exp(2 * z / 3)
                let sd = 0.5 * sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1)
                let newLeft = max(left, Int(floor(Double(k) - m * s / n + sd)))
                let newRight = min(right, Int(floor(Double(k) + (n - m) * s / n + sd)))
                select(k: k, left: newLeft, right: newRight, axis: axis)
            }

            let t = coords[2 * k + axis]
            var i = left
            var j = right

            swapItem(i, k)
            if coords[2 * right + axis] > t { swapItem(left, right) }

            while i < j {
                swapItem(i, j)
                i += 1
                j -= 1
                while coords[2 * i + axis] < t { i += 1 }
                while coords[2 * j + axis] > t { j -= 1 }
            }

            if coords[2 * left + axis] == t {
                swapItem(left, j)
            } else {
                j += 1
                swapItem(j, right)
            }

            if j <= k { left = j + 1 }
            if k <= j { right = j - 1 }
        }
    }

    private func swapItem(_ i: Int, _ j: Int) {
        ids.swapAt(i, j)
        coords.swapAt(2 * i, 2 * j)
        coords.swapAt(2 * i + 1, 2 * j + 1)
    }

    private func rangeSearch(nodeIndex: Int, left: Int, right: Int, minX: Double, minY: Double, maxX: Double, maxY: Double, result: inout [Int]) {
        if left > right { return }

        if right - left <= nodeSize {
            for i in left...right {
                let x = coords[2 * i]
                let y = coords[2 * i + 1]
                if x >= minX && x <= maxX && y >= minY && y <= maxY {
                    result.append(ids[i])
                }
            }
            return
        }

        let mid = (left + right) >> 1
        let x = coords[2 * mid]
        let y = coords[2 * mid + 1]

        if x >= minX && x <= maxX && y >= minY && y <= maxY {
            result.append(ids[mid])
        }

        if nodeIndex % 2 == 0 {
            if minX <= x && mid - 1 >= left {
                rangeSearch(nodeIndex: nodeIndex + 1, left: left, right: mid - 1, minX: minX, minY: minY, maxX: maxX, maxY: maxY, result: &result)
            }
            if maxX >= x && mid + 1 <= right {
                rangeSearch(nodeIndex: nodeIndex + 1, left: mid + 1, right: right, minX: minX, minY: minY, maxX: maxX, maxY: maxY, result: &result)
            }
        } else {
            if minY <= y && mid - 1 >= left {
                rangeSearch(nodeIndex: nodeIndex + 1, left: left, right: mid - 1, minX: minX, minY: minY, maxX: maxX, maxY: maxY, result: &result)
            }
            if maxY >= y && mid + 1 <= right {
                rangeSearch(nodeIndex: nodeIndex + 1, left: mid + 1, right: right, minX: minX, minY: minY, maxX: maxX, maxY: maxY, result: &result)
            }
        }
    }

    private func withinSearch(nodeIndex: Int, left: Int, right: Int, x: Double, y: Double, r2: Double, result: inout [Int]) {
        if left > right { return }

        if right - left <= nodeSize {
            for i in left...right {
                let px = coords[2 * i]
                let py = coords[2 * i + 1]
                if squaredDistance(x, y, px, py) <= r2 {
                    result.append(ids[i])
                }
            }
            return
        }

        let mid = (left + right) >> 1
        let px = coords[2 * mid]
        let py = coords[2 * mid + 1]

        if squaredDistance(x, y, px, py) <= r2 {
            result.append(ids[mid])
        }

        if nodeIndex % 2 == 0 {
            if x - sqrt(r2) <= px && mid - 1 >= left {
                withinSearch(nodeIndex: nodeIndex + 1, left: left, right: mid - 1, x: x, y: y, r2: r2, result: &result)
            }
            if x + sqrt(r2) >= px && mid + 1 <= right {
                withinSearch(nodeIndex: nodeIndex + 1, left: mid + 1, right: right, x: x, y: y, r2: r2, result: &result)
            }
        } else {
            if y - sqrt(r2) <= py && mid - 1 >= left {
                withinSearch(nodeIndex: nodeIndex + 1, left: left, right: mid - 1, x: x, y: y, r2: r2, result: &result)
            }
            if y + sqrt(r2) >= py && mid + 1 <= right {
                withinSearch(nodeIndex: nodeIndex + 1, left: mid + 1, right: right, x: x, y: y, r2: r2, result: &result)
            }
        }
    }

    private func squaredDistance(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Double {
        let dx = ax - bx
        let dy = ay - by
        return dx * dx + dy * dy
    }
}

// MARK: - Coordinate Transformation Utilities

private extension KDBush {
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
