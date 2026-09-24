//
//  QuadTree.swift
//  Boids
//
//  Created by Fasith on 16/09/26.
//
import Foundation
import CoreGraphics

final class QuadTree<Item>{
    private let root: NodeTree<Item>

    private(set) var count: Int = 0
    init(bounds: CGRect, nodeCapacity: Int = 4, maxDepth: Int = 30, depth: Int = 0, positionOf: @escaping (Item) -> CGPoint) {
        root = NodeTree<Item>(bounds: bounds, nodeCapacity: nodeCapacity, maxDepth: maxDepth, depth: depth, positionOf: positionOf)
    }

    @discardableResult
    func insert(_ item: Item) -> Bool {
        let inserted = root.insert(item)

        if inserted {
            count += 1
        }

        return inserted
    }

    func query(in range: CGRect) -> [Item] {
        root.query(in: range)
    }

    func allItems() -> [Item] {
        root.allItems()
    }
}

final class NodeTree<Item>{
    
    private let bounds : CGRect
    private var items = [Item]()
    private let nodeCapacity : Int
    private let maxDepth : Int
    private let depth : Int
    private let positionOf : (Item) -> CGPoint
    private var northeast: NodeTree?
    private var northwest: NodeTree?
    private var southeast: NodeTree?
    private var southwest: NodeTree?
    
    private var isDivided: Bool {
        northeast != nil
    }
    
    init(bounds: CGRect, nodeCapacity: Int, maxDepth: Int, depth: Int, positionOf: @escaping (Item) -> CGPoint) {
        self.bounds = bounds
        self.nodeCapacity = nodeCapacity
        self.maxDepth = maxDepth
        self.depth = depth
        self.positionOf = positionOf
    }
    
    func subDivide() {
        let halfWidth = bounds.width / 2
        let halfHeight = bounds.height / 2
        
        northeast = NodeTree(bounds: CGRect(x: bounds.minX + halfWidth, y: bounds.minY, width: halfWidth, height: halfHeight), nodeCapacity: nodeCapacity, maxDepth: maxDepth, depth: depth + 1, positionOf: positionOf )
        northwest = NodeTree(bounds: CGRect(x: bounds.minX, y: bounds.minY, width: halfWidth, height: halfHeight), nodeCapacity: nodeCapacity, maxDepth: maxDepth, depth: depth + 1 , positionOf: positionOf)
        southeast = NodeTree(bounds: CGRect(x: bounds.minX + halfWidth, y: bounds.minY + halfHeight, width: halfWidth, height: halfHeight), nodeCapacity: nodeCapacity, maxDepth: maxDepth, depth: depth + 1, positionOf: positionOf )
        southwest = NodeTree(bounds: CGRect(x: bounds.minX, y: bounds.minY + halfHeight, width: halfWidth, height: halfHeight), nodeCapacity: nodeCapacity, maxDepth: maxDepth, depth: depth + 1, positionOf: positionOf )

        let oldItems = items
        items.removeAll(keepingCapacity: true)

        for item in oldItems {
            if !insertIntoChildren(item) {
                items.append(item)
            }
        }
    }
    
    private func insertIntoChildren(_ item: Item) -> Bool {
        if northeast!.insert(item) { return true }
        if northwest!.insert(item) { return true }
        if southeast!.insert(item) { return true }
        if southwest!.insert(item) { return true }

        return false
    }
    
    @discardableResult
    func insert(_ item: Item) -> Bool {
        guard bounds.contains(positionOf(item)) else {
            return false
        }

        if items.count < nodeCapacity || depth >= maxDepth {
            items.append(item)
            return true
        }

        if !isDivided {
            subDivide()
        }

        return insertIntoChildren(item)
    }

    func query(in range: CGRect) -> [Item] {
        guard bounds.intersects(range) else {
            return []
        }

        var result = items.filter { range.contains(positionOf($0)) }

        if isDivided {
            result += northeast!.query(in: range)
            result += northwest!.query(in: range)
            result += southeast!.query(in: range)
            result += southwest!.query(in: range)
        }

        return result
    }

    func allItems() -> [Item] {
        var result = items

        if isDivided {
            result += northeast!.allItems()
            result += northwest!.allItems()
            result += southeast!.allItems()
            result += southwest!.allItems()
        }

        return result
    }

    
}

