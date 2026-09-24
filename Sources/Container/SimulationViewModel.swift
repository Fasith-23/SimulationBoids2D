//
//  SimulationViewModel.swift
//  Boids
//
//  Created by Fasith on 05/09/26.
//

import SwiftUI

@MainActor
@Observable
class SimulationViewModel {
    var boids = [Boid]()
    var bounds: CGRect = .zero
    var seekPosition: CGPoint? = nil
    var showMenu = false
    var pauseSim = false
    var goNextFrame = false
    
    private var boidTree = QuadTree<Int>(bounds: .zero){i in
            .zero
    }
    private var boidHash = SpatialHash<Int>(cellSize: 50) { i in
            .zero
    }

    init(boidParameters : BoidParameters){
        self.boidCount = boidParameters.boidCount
        self.maxSpeed = boidParameters.maxSpeed
        self.maxForce = boidParameters.steeringForce
        self.separationRadius = boidParameters.visibilityRange
        self.seekRadius = boidParameters.seekRadius
        self.separationWeight = boidParameters.separationWeight
        self.alignmentWeight = boidParameters.alignmentWeight
        self.cohesionWeight = boidParameters.cohesionWeight
        self.seekWeight = boidParameters.seekWeight
        self.searchMethod = boidParameters.searchMethod
        
        boids = (0..<Int(boidParameters.boidCount)).map { _ in
            Boid(
                position: CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -2...2),
                    dy: CGFloat.random(in: -2...2)
                )
            )
        }
    }
    
    var boidCount: CGFloat  /// BOID COUNT
    var maxSpeed: CGFloat /// MAX SPEED
    var maxForce: CGFloat   /// STEERING FORCE
    var separationRadius: CGFloat /// VISIBILITY RANGE
    var alignmentRadius: CGFloat {
        2 * separationRadius
    }// 2* SEP RADIUS
    //    var cohesionRadius: CGFloat {
    //        2 * separationRadius
    //    } // 2* SEP RADIUS
    //
    /// Distance at which boids respond to touch target
    var seekRadius: CGFloat
    
    var separationWeight: CGFloat /// SEP WEGHT
    var alignmentWeight: CGFloat  ///
    var cohesionWeight: CGFloat  ///
    var seekWeight: CGFloat
    var searchMethod : SimulationDataStructure
        
    private var simulationTask: Task<Void, Never>?
//    private let chunkSize = 25
    func startSimulation() {
        guard simulationTask == nil else { return }
        
        simulationTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                
                do {
                    try await Task.sleep(for: .milliseconds(16))
                } catch {
                    // The task was cancelled.
                    break
                }
            }
        }
    }
    
    func stopSimulation() {
        simulationTask?.cancel()
        simulationTask = nil
    }
    
    private func tick() async {
        if pauseSim {
            if goNextFrame {
                goNextFrame = false
                
                for _ in 0..<3 {
                    await update()
                }
            }
        } else {
            await update()
        }
    }
    
    func update() async {
        let targetCount = max(0, Int(boidCount.rounded()))
        if boids.count < targetCount {
            let numberToAdd = targetCount - boids.count
            let newBoids = (0..<numberToAdd).map { _ in
                Boid(
                    position: CGPoint(
                        x: CGFloat.random(in: 0...bounds.width),
                        y: CGFloat.random(in: 0...bounds.height)
                    ),
                    velocity: CGVector(
                        dx: CGFloat.random(in: -2...2),
                        dy: CGFloat.random(in: -2...2)
                    )
                )
            }
            boids += newBoids
        }
        else if boids.count > targetCount {
            let numberToRemove = boids.count - targetCount
            boids.removeLast(numberToRemove)
        }
        //        print(bounds, boidCount, boids.count)
        switch searchMethod {
        case .naive:
            break
        case .quadTree:
            boidTree = QuadTree<Int>(bounds: bounds) { [weak self] index in
                self?.boids[index].position ?? .zero
            }
            for i in 0..<boids.count {
                boidTree.insert(i)
            }
        case .spatialHash:
            boidHash = SpatialHash<Int>(cellSize: 2 * separationRadius){ [weak self] index in
                self?.boids[index].position ?? .zero
            }
            for i in 0..<boids.count {
                boidHash.insert(i)
            }
        }
        boids = boids.enumerated().map { index, boid in
            calculatePosition(for: boid)
        }
        
        // TODO: Taskgroups need to be non isolated from current actor => too many copies of data - boids, boidtree/hash, all parameters -- is it worth for the parallelisation
//        let operationCount = (targetCount + chunkSize - 1) / chunkSize
//        let boidCopies = await withTaskGroup(
//            of: [Boid].self,
//            returning: [Boid].self
//        ) { group in
//
//            for operation in 0..<operationCount {
//                let start = operation * chunkSize
//                let end = min(start + chunkSize, targetCount)
//
//                let range = start..<end
//
//                group.addTask {
//                    await self.calculatePosition(for: range)
//                }
//            }
//
//            var newBoids: [Boid] = []
//            newBoids.reserveCapacity(targetCount)
//
//            for await result in group {
//                // Results are appended in task-completion order.
//                newBoids.append(contentsOf: result)
//            }
//
//            return newBoids
//        }
//        boids = boidCopies

    }
    
    // MARK: - Boid position calculations
    private func calculatePosition(for boid : Boid) -> Boid {
        var newBoid = boid
        var acceleration = CGVector.zero
        acceleration = addVectors(acceleration, calculateSteer(for: newBoid))
        
        if let seekTarget = seekPosition {
            acceleration = addVectors(acceleration, multiplyVector(calculateSeek(for: newBoid, target: seekTarget), seekWeight))
        }
        
        acceleration = limitVector(acceleration, max: maxForce)
        
        newBoid.velocity = addVectors(newBoid.velocity, acceleration)
        newBoid.velocity = limitVector(newBoid.velocity, max: maxSpeed)
        
        newBoid.position = CGPoint(
            x: newBoid.position.x + newBoid.velocity.dx,
            y: newBoid.position.y + newBoid.velocity.dy
        )
        
        newBoid.position.x = newBoid.position.x < 0 ? bounds.width : (newBoid.position.x > bounds.width ? 0 : newBoid.position.x)
        newBoid.position.y = newBoid.position.y < 0 ? bounds.height : (newBoid.position.y > bounds.height ? 0 : newBoid.position.y)
        
        return newBoid
    }
    
    private func calculateSteer(for boid : Boid) -> CGVector {
        var steerForSeparation = CGVector.zero
        var steerForAlignment = CGVector.zero
        var sumForCohesion = CGPoint.zero
        var steerForCohesion = CGVector.zero
        var countForSeparation = 0
        var countForAlignmentCohesion = 0
        let neighbourIndices: [Int]
        switch searchMethod {
        case .naive:
            neighbourIndices = Array(boids.indices)
//            print("twnk")
        case .quadTree:
            let visibilityRange = CGRect(origin: CGPoint(x: boid.position.x - separationRadius, y: boid.position.y - separationRadius), size: CGSize(width: 2*separationRadius, height: 2*separationRadius))
            
            neighbourIndices = boidTree.query(in: visibilityRange)
//            print("QT")
        case .spatialHash:
            neighbourIndices = boidHash.query(around: boid.position)
//            print("sh")
        }

        for neighbourIndex in neighbourIndices {
            let neighbour = boids[neighbourIndex]
            if neighbour.position == boid.position {
                continue
            }
            
            let distance = distanceBetween(boid.position, neighbour.position)
            if distance < separationRadius {
                let diff = CGVector(
                    dx: boid.position.x - neighbour.position.x,
                    dy: boid.position.y - neighbour.position.y
                )
                let normalized = normalizeVector(diff)
                steerForSeparation = addVectors(steerForSeparation, multiplyVector(normalized, 1.0 / distance))
                countForSeparation += 1
            }
            if distance < 2 * separationRadius {
                steerForAlignment = addVectors(steerForAlignment, neighbour.velocity)
                sumForCohesion = CGPoint(x: sumForCohesion.x + neighbour.position.x, y: sumForCohesion.y + neighbour.position.y)
                countForAlignmentCohesion += 1
            }
        }
        
        if countForSeparation > 0{
            steerForSeparation = multiplyVector(steerForSeparation, 1.0/CGFloat(countForSeparation))
            steerForSeparation = constraintValue(forSteer: steerForSeparation, ofBoid: boid.velocity)
        }
        if countForAlignmentCohesion > 0 {
            steerForAlignment = multiplyVector(steerForAlignment, 1.0/CGFloat(countForAlignmentCohesion))
            steerForAlignment = constraintValue(forSteer: steerForAlignment, ofBoid: boid.velocity)
            
            let average = CGPoint(x: sumForCohesion.x / CGFloat(countForAlignmentCohesion), y: sumForCohesion.y / CGFloat(countForAlignmentCohesion))
            steerForCohesion = CGVector(dx: average.x - boid.position.x, dy: average.y - boid.position.y)
            steerForCohesion = constraintValue(forSteer: steerForCohesion, ofBoid: boid.velocity)
        }
        
        let combinedSteer = addVectors(addVectors(multiplyVector(steerForSeparation, separationWeight), multiplyVector(steerForAlignment, alignmentWeight)), multiplyVector(steerForCohesion, cohesionWeight))
        return combinedSteer
    }
    
    private func constraintValue(forSteer: CGVector, ofBoid boidVelocity: CGVector) -> CGVector {
        var steer = normalizeVector(forSteer)
        steer = multiplyVector(steer, maxSpeed)
        steer = subtractVectors(steer, boidVelocity)
        steer = limitVector(steer, max: maxForce)
        return steer
    }
    
    
    private func calculateSeek(for boid: Boid, target: CGPoint) -> CGVector {
        let distance = distanceBetween(boid.position, target)
        
        if distance > 0 && distance < seekRadius {
            let seekTargetForce = CGVector(dx: target.x - boid.position.x, dy: target.y - boid.position.y)
            return constraintValue(forSteer: seekTargetForce, ofBoid: boid.velocity)
        }
        
        return CGVector.zero
    }
    
    // MARK: - Boid UI calculations
    
//    func colorFromSpeed(forIndex i: Int) -> Color {
//        guard boids.indices.contains(i), maxSpeed > 0 else {
//            return .clear
//        }
//
//        let speed = magnitudeOfVector(boids[i].velocity)
//        let normalizedSpeed = min(max(speed / maxSpeed, 0), 1)
//
//        // Light blue → pink
//        let red = 0.65 + (0.35 * normalizedSpeed)
//        let green = 0.85 - (0.55 * normalizedSpeed)
//        let blue = 1.0
//
//        return Color(
//            red: red,
//            green: green,
//            blue: blue
//        )
//    }

    func colorFromSpeed(forIndex i: Int) -> Color {
        guard boids.indices.contains(i), maxSpeed > 0 else {
            return .clear
        }

        let speed = magnitudeOfVector(boids[i].velocity)
        let normalizedSpeed = min(max(speed / maxSpeed, 0), 1)

        // Hue: blue → cyan → green → yellow → orange → red
        let hue = (2.0 / 3.0) * (1.0 - normalizedSpeed)

        return Color(
            hue: hue,
            saturation: 1.0,
            brightness: 1.0
        )
    }
    
    func angleOfVelocity(forIndex i: Int) -> Angle {
        if i>=boids.count { return .zero }
        let velocity = boids[i].velocity
        let angle = atan2(velocity.dy, velocity.dx)
        return Angle(radians: Double(angle) + .pi / 2)
    }
    
    // MARK: - Vector Math Helpers
    
    private func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func addVectors(_ v1: CGVector, _ v2: CGVector) -> CGVector {
        return CGVector(dx: v1.dx + v2.dx, dy: v1.dy + v2.dy)
    }
    
    private func subtractVectors(_ v1: CGVector, _ v2: CGVector) -> CGVector {
        return CGVector(dx: v1.dx - v2.dx, dy: v1.dy - v2.dy)
    }
    
    private func multiplyVector(_ v: CGVector, _ scalar: CGFloat) -> CGVector {
        return CGVector(dx: v.dx * scalar, dy: v.dy * scalar)
    }
    
    private func normalizeVector(_ v: CGVector) -> CGVector {
        let magnitude = magnitudeOfVector(v)
        if magnitude > 0 {
            return CGVector(dx: v.dx / magnitude, dy: v.dy / magnitude)
        }
        return v
    }
    
    private func magnitudeOfVector(_ v: CGVector) -> CGFloat {
        return sqrt(v.dx * v.dx + v.dy * v.dy)
    }
    
    private func limitVector(_ v: CGVector, max: CGFloat) -> CGVector {
        let magnitude = magnitudeOfVector(v)
        if magnitude > max {
            return multiplyVector(normalizeVector(v), max)
        }
        return v
    }
}
    






