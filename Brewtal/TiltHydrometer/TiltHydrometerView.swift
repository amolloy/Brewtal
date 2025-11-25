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
    }
}

#Preview {
    TiltHydrometerView()
}
