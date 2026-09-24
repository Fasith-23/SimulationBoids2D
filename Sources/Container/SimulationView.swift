//
//  SimulationView.swift
//  Boids
//
//  Created by Fasith on 30/08/26.
//

import SwiftUI

public struct BoidsView: View {
    @State var viewModel : SimulationViewModel
    var menuAvailable : Bool
    
    public init(){
        _viewModel = State(initialValue: SimulationViewModel(boidParameters: .init()))
        self.menuAvailable = false
    }
    
    public init(displayMenu : Bool) {
        _viewModel = State(initialValue: SimulationViewModel(boidParameters: .init()))
        self.menuAvailable = displayMenu
    }
    
    public init(boidParameters: BoidParameters){
        _viewModel = State(initialValue: SimulationViewModel(boidParameters: boidParameters))
        self.menuAvailable = false
    }

    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    
                    ForEach(0..<viewModel.boids.count, id: \.self) { index in
                        BoidShape()
                            .fill(viewModel.colorFromSpeed(forIndex: index).opacity(0.8))
                            .frame(width: 8, height: 12)
                            .rotationEffect(viewModel.angleOfVelocity(forIndex: index))
                            .position(viewModel.boids[index].position)
                        
                    }
                    .allowsHitTesting(false)
                }
                .background(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            viewModel.seekPosition = value.location
                        }
                        .onEnded { _ in
                            viewModel.seekPosition = nil
                        }
                )
                .onAppear {
                    viewModel.bounds = CGRect(origin: .zero, size: geometry.size)
                    viewModel.startSimulation()
                }
                .onDisappear() {
                    viewModel.stopSimulation()
                }
                .onChange(of: geometry.size) { _ , newSize  in
                    viewModel.bounds = CGRect(origin: .zero, size: newSize)
                }
            }
            if menuAvailable {
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.showMenu.toggle()
                        }
                    }) {
                        Image(systemName: "arrowtriangle.up.circle.fill")
                            .resizable()
                            .rotationEffect(.degrees(viewModel.showMenu ? 180 : 0))
                            .frame(width: 30, height: 30)
                            .background(.white.opacity(0.2), in: .rect(cornerRadius: 30))
                            .foregroundStyle(.white)
                    }
                    
                    if viewModel.showMenu {
                        DropUpMenu(boidCountSlider: CustomSlider(value: $viewModel.boidCount, range: BoidConstants.boidCount.range, step: 5, label: "Boid Count", decimalFormatting: "%.0f"), items: [CustomSlider(value: $viewModel.separationRadius, range: BoidConstants.visibilityRange.range, step: 1, label: "Visibility Range", decimalFormatting: "%.0f"), CustomSlider(value: $viewModel.maxSpeed, range: BoidConstants.maxSpeed.range, step: 0.5, label: "Maximum Speed"), CustomSlider(value: $viewModel.maxForce, range: BoidConstants.maxForce.range, step: 0.01, label: "Steering Force", decimalFormatting: "%.2f"), CustomSlider(value: $viewModel.separationWeight, range: BoidConstants.separationWeight.range, step: 0.5, label: "Separation Weight"), CustomSlider(value: $viewModel.alignmentWeight, range: BoidConstants.alignmentWeight.range, step: 0.5, label: "Alignment Weight"), CustomSlider(value: $viewModel.cohesionWeight, range: BoidConstants.cohesionWeight.range, step: 0.5, label: "Cohesion Weight")])
                            .environment(viewModel)
                            .padding(.horizontal)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom)
                                        .combined(with: .opacity),
                                    removal: .move(edge: .bottom)
                                        .combined(with: .opacity)
                                )
                            )
                        
                    }
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
    
    
}



public struct BoidShape: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

//#Preview {
//    SimulationView()
////        .frame(width: 400, height: 600)
//}
