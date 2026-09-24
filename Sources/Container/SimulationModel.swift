//
//  SimulationModel.swift
//  Boids
//
//  Created by Fasith on 05/09/26.
//
import SwiftUI

struct Boid {
    var position: CGPoint
    var velocity: CGVector
    
    init(position: CGPoint, velocity: CGVector) {
        self.position = position
        self.velocity = velocity
    }
}

struct ValueLimits<Value: Comparable & Sendable> : Sendable{
     let defaultValue: Value
     let range: ClosedRange<Value>

     init(
        defaultValue: Value,
        range: ClosedRange<Value>
    ) {
        precondition(
            range.contains(defaultValue),
            "Default value must be inside the allowed range."
        )

        self.defaultValue = defaultValue
        self.range = range
    }

     func clamped(_ value: Value) -> Value {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

enum SimulationDataStructure: String, CaseIterable {
    case naive = "Naive"
    case quadTree = "Quad Tree"
    case spatialHash = "Spatial Hash"
}

enum BoidConstants {
    static let boidCount = ValueLimits(
        defaultValue: CGFloat(100),
        range: CGFloat(0)...CGFloat(400)
    )

    static let maxSpeed = ValueLimits(
        defaultValue: CGFloat(3.0),
        range: CGFloat(1.0)...CGFloat(8.0)
    )

    static let maxForce = ValueLimits(
        defaultValue: CGFloat(0.05),
        range: CGFloat(0.03)...CGFloat(0.1)
    )

    static let visibilityRange = ValueLimits(
        defaultValue: CGFloat(25.0),
        range: CGFloat(10.0)...CGFloat(100.0)
    )

    static let seekRadius = ValueLimits(
        defaultValue: CGFloat(200.0),
        range: CGFloat(10.0)...CGFloat(1000.0)
    )

    static let separationWeight = ValueLimits(
        defaultValue: CGFloat(1.5),
        range: CGFloat(0.0)...CGFloat(2.0)
    )

    static let alignmentWeight = ValueLimits(
        defaultValue: CGFloat(1.0),
        range: CGFloat(0.0)...CGFloat(2.0)
    )

    static let cohesionWeight = ValueLimits(
        defaultValue: CGFloat(1.0),
        range: CGFloat(0.0)...CGFloat(2.0)
    )

    static let seekWeight = ValueLimits(
        defaultValue: CGFloat(10.0),
        range: CGFloat(0.0)...CGFloat(10.0)
    )
}

// TODO: Declare all boid params here ... change the inits in view and viewModel ... and the vars in both ...Also use it implement nonisolated func for parallelisation

 public struct BoidParameters {
     var boidCount: CGFloat
     var maxSpeed: CGFloat
     var steeringForce: CGFloat
     var visibilityRange: CGFloat
     var seekRadius: CGFloat
     var separationWeight: CGFloat
     var alignmentWeight: CGFloat
     var cohesionWeight: CGFloat
     var seekWeight: CGFloat
     var searchMethod: SimulationDataStructure

     init(
        boidCount: CGFloat = BoidConstants.boidCount.defaultValue,
        maxSpeed: CGFloat = BoidConstants.maxSpeed.defaultValue,
        steeringForce: CGFloat = BoidConstants.maxForce.defaultValue,
        visibilityRange: CGFloat = BoidConstants.visibilityRange.defaultValue,
        seekRadius: CGFloat = BoidConstants.seekRadius.defaultValue,
        separationWeight: CGFloat = BoidConstants.separationWeight.defaultValue,
        alignmentWeight: CGFloat = BoidConstants.alignmentWeight.defaultValue,
        cohesionWeight: CGFloat = BoidConstants.cohesionWeight.defaultValue,
        seekWeight: CGFloat = BoidConstants.seekWeight.defaultValue,
        searchMethod: SimulationDataStructure = .spatialHash
    ) {
        self.boidCount = BoidConstants.boidCount.clamped(boidCount)
        self.maxSpeed = BoidConstants.maxSpeed.clamped(maxSpeed)
        self.steeringForce = BoidConstants.maxForce.clamped(steeringForce)
        self.visibilityRange = BoidConstants.visibilityRange.clamped(visibilityRange)
        self.seekRadius = BoidConstants.seekRadius.clamped(seekRadius)
        self.separationWeight = BoidConstants.separationWeight.clamped(separationWeight)
        self.alignmentWeight = BoidConstants.alignmentWeight.clamped(alignmentWeight)
        self.cohesionWeight = BoidConstants.cohesionWeight.clamped(cohesionWeight)
        self.seekWeight = BoidConstants.seekWeight.clamped(seekWeight)
        self.searchMethod = searchMethod
    }
}
