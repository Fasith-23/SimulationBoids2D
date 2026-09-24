//
//  CustomSliderView.swift
//  Boids
//
//  Created by Fasith on 07/09/26.
//

import SwiftUI

struct DropUpMenu: View {
    @Environment(SimulationViewModel.self) private var viewModel
    let boidCountSlider : CustomSlider
    let items : [CustomSlider]
    private let adaptiveColumns = [
        GridItem(.adaptive(minimum: 180, maximum: 500), spacing: 0)
    ]
    var body: some View {
        VStack{
            HStack{
                
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.pauseSim.toggle()
                        }
                    }) {
                        Image(systemName: viewModel.pauseSim ? "play.circle.fill" : "pause.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.white)
                            .background(.clear)
                    }
                    .padding(.leading)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if viewModel.pauseSim{
                                viewModel.goNextFrame.toggle()
                            }
                        }
                    }) {
                        Image(systemName: "arrowshape.turn.up.left.2.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(180))
                            .foregroundStyle(.white)
                            .background(.clear)
                        
                    }
                
                
                boidCountSlider
                    
            }
            
            .padding(.top)
            LazyVGrid(columns: adaptiveColumns, spacing: 0){
                ForEach(items){ slider in
                    slider
                }
            }
            HStack{
                Text("Search Method")
                    .font(.footnote)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal)
            HStack {
                ForEach(Array(SimulationDataStructure.allCases.enumerated()), id: \.element) { index, dataStructure in
                    Button(action: {
                        viewModel.searchMethod = dataStructure
                    }) {
                        Text(dataStructure.rawValue)
                            .font(.footnote.bold())
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                    }
                    .background(viewModel.searchMethod == dataStructure ? .white.opacity(0.2) : Color(hex: "F5A9B8").opacity(1), in : .rect(cornerRadius: 20))
                    
                    if index < SimulationDataStructure.allCases.count - 1 {
                        Spacer()
                    }

                    
                }
            }
            .padding(.bottom)
            .padding(.horizontal)
            
            
        }
        .background(.white.opacity(0.2), in: .rect(cornerRadius: 20))
        .frame(alignment: .bottom)
    }
}
struct CustomSlider: View, Identifiable {
    let id = UUID()
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat?
    let label: String
    var decimalFormatting: String?
    
    @State private var lastCoordinateValue: CGFloat = 0

    var body: some View {
        VStack {
            HStack {
                Text("\(label)")
                    .font(.footnote)
                Spacer()
                Text("\(value, specifier: decimalFormatting ?? "%.1f")")
                    .font(.subheadline)
                    
            }
            .foregroundStyle(.white)

            GeometryReader { geometry in
                let height = geometry.size.height
                let thumbSize = height * 0.8
                let trackWidth = geometry.size.width
                let usableWidth = trackWidth - thumbSize

                let valueRange : CGFloat = range.upperBound - range.lowerBound
                let normalizedValue: CGFloat = valueRange > 0
                ? (value - range.lowerBound) / valueRange
                    : 0

                let thumbOffset = normalizedValue * usableWidth

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .foregroundStyle(Color(hex: "F5A9B8"))
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(x: thumbOffset)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let offset = min(
                                max(gesture.location.x - thumbSize / 2, 0),
                                usableWidth
                            )


                            let percentage = offset / usableWidth

                            let rawValue =
                                range.lowerBound + percentage * valueRange

                            value = snappedValue(rawValue)
                        }
                )
            }
            .frame(height: 20)
        }
        .padding()
    }
    
    private func snappedValue(_ value: CGFloat) -> CGFloat {
        let stepCount = step ?? 0.1
        guard stepCount > 0 else {
            return min(max(value, range.lowerBound), range.upperBound)
        }

        let clampedValue = min(
            max(value, range.lowerBound),
            range.upperBound
        )

        let stepsFromMinimum =
            round((clampedValue - range.lowerBound) / stepCount)

        let steppedValue =
            range.lowerBound + stepsFromMinimum * stepCount

        return min(
            max(steppedValue, range.lowerBound),
            range.upperBound
        )
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

//#Preview {
//    DropUpMenu()
//}
