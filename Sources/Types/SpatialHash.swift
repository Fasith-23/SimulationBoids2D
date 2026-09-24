//
//  SpatialHash.swift
//  Boids
//
//  Created by Fasith on 19/09/26.
//

import Foundation

final class SpatialHash<Item> {
    private struct Cell: Hashable {
        let x: Int
        let y: Int
    }

    private let cellSize: CGFloat
    private let positionOf: (Item) -> CGPoint

    private var buckets: [Cell: [Item]] = [:]

    init(
        cellSize: CGFloat,
        positionOf: @escaping (Item) -> CGPoint
    ) {
        precondition(cellSize > 0)

        self.cellSize = cellSize
        self.positionOf = positionOf
    }

    func removeAll(keepingCapacity: Bool = true) {
        buckets.removeAll(keepingCapacity: keepingCapacity)
    }

    func insert(_ item: Item) {
        let cell = cellFor(positionOf(item))
        buckets[cell, default: []].append(item)
    }

    func insert<S: Sequence>(_ items: S) where S.Element == Item {
        for item in items {
            insert(item)
        }
    }

    func query(
        around center: CGPoint
    ) -> [Item] {
        guard cellSize >= 0 else { return [] }

        let cellSizeSquared = cellSize * cellSize

        let minCellX = cellCoordinate(center.x - cellSize)
        let maxCellX = cellCoordinate(center.x + cellSize)
        let minCellY = cellCoordinate(center.y - cellSize)
        let maxCellY = cellCoordinate(center.y + cellSize)

        var result: [Item] = []

        for cellX in minCellX...maxCellX {
            for cellY in minCellY...maxCellY {
                let cell = Cell(x: cellX, y: cellY)

                guard let items = buckets[cell] else {
                    continue
                }

                for item in items {
                    let position = positionOf(item)
                    let dx = position.x - center.x
                    let dy = position.y - center.y

                    if dx * dx + dy * dy <= cellSizeSquared {
                        result.append(item)
                    }
                }
            }
        }

        return result
    }

    func count() -> Int {
        buckets.values.reduce(0) { $0 + $1.count }
    }

    private func cellFor(_ position: CGPoint) -> Cell {
        Cell(
            x: cellCoordinate(position.x),
            y: cellCoordinate(position.y)
        )
    }

    private func cellCoordinate(_ value: CGFloat) -> Int {
        Int(floor(value / cellSize))
    }
}
