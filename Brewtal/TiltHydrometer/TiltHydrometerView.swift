//
//  TiltHydrometerView.swift
//  BrewVision
//
//  Created by Andy Molloy on 11/24/25.
//

import CoreBluetooth
import CoreLocation
import SwiftUI

struct TiltHydrometerView: View {
    @StateObject private var viewModel = TiltHydrometerViewModel()
    
    var body: some View {
        VStack {
            Menu {
                ForEach(TiltHydrometerViewModel.TiltColor.allCases, id: \.self) { color in
                    Button(action: {
                        viewModel.setSelectedColor(color)
                    }) {
                        if color == viewModel.selectedColor {
                            Label(color.rawValue.capitalized, systemImage: "checkmark")
                        } else {
                            Text(color.rawValue.capitalized)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedColor.rawValue.capitalized)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.5))
                )
            }
            .padding(.bottom, 16)
            
            if let temperature = viewModel.temperature,
               let gravity = viewModel.gravity {
                Text(String(format: "%.1f°F", temperature))
                    .font(.largeTitle)
                Text(String(format: "%.3f SG", gravity))
                    .font(.largeTitle)
            } else {
                Text("--.-°F")
                    .font(.largeTitle)
                Text("---.--- SG")
                    .font(.largeTitle)
            }
            Text(viewModel.status)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    TiltHydrometerView()
}
