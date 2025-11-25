//
//  BrewtalAll.swift
//  Brewtal
//
//  Created by Andy Molloy on 11/17/25.
//

import SwiftUI

@main
struct BrewtalAll: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                BrewVisionTemperatureView()
                    .tabItem {
                        Label("BrewVision Thermometer", systemImage: "thermometer")
                    }
				TiltHydrometerView()
					.tabItem {
						Label("Tilt Hydrometer", systemImage: "drop")
					}
            }
        }
    }
}
