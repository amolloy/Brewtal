//
//  BrewVisionTemperatureView.swift
//  Brewtal
//
//  Created by Andy Molloy on 11/17/25.
//

import SwiftUI
import Combine

struct BrewVisionTemperatureView: View {
	@StateObject private var viewModel = BluetoothViewModel()

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				HStack {
					Text(viewModel.status)
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity, alignment: .leading)

					Button("Read Temp") {
						viewModel.readAllValues()
					}
					.buttonStyle(.bordered)
					.disabled(viewModel.peripheral == nil)
				}
				.padding()

				Spacer()

				VStack {
					if let temp = viewModel.currentTemperatureFahrenheit {
						Text(String(format: "%.1f", temp))
							.font(.system(size: 120, weight: .bold, design: .rounded))
							.lineLimit(1)
							.minimumScaleFactor(0.5)

						Text("°F")
							.font(.system(size: 60, weight: .light, design: .rounded))
							.foregroundStyle(.secondary)
					} else {
						Text("--.-")
							.font(.system(size: 120, weight: .bold, design: .rounded))
							.foregroundStyle(.gray.opacity(0.3))

						Text("°F")
							.font(.system(size: 60, weight: .light, design: .rounded))
							.foregroundStyle(.gray.opacity(0.3))
					}
				}
				.padding()

				Spacer()
				Spacer()
			}
			.navigationTitle("BrewVision")
			.onAppear {
				viewModel.startScanning()
			}
		}
	}
}
