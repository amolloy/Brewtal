//  TiltHydrometerViewModel.swift
//  Brewtal
//
//  Created by Assistant on 11/24/25.
//

import Combine
import CoreBluetooth
import CoreLocation
import Foundation

class TiltHydrometerViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CLLocationManagerDelegate {
    @Published var temperature: Double? = nil
    @Published var gravity: Double? = nil
    @Published var status: String = "Initializing..."

    private var centralManager: CBCentralManager!
    private var locationManager: CLLocationManager!
    
    private let tiltUUID = UUID(uuidString: "a495bb30-c5b1-4b44-b512-1370f02d74de")!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            status = "Scanning for Tilt hydrometers..."
            startScanningForBeacons()
        } else {
            status = "Bluetooth state: \(central.state.rawValue)"
        }
    }

    func startScanningForBeacons() {
        let beaconRegion = CLBeaconRegion(uuid: tiltUUID, identifier: "Tilt")
        locationManager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying constraint: CLBeaconIdentityConstraint) {
        guard let tiltBeacon = beacons.first else {
            status = "No Tilt hydrometers found"
            temperature = nil
            gravity = nil
            return
        }

		temperature = Double(tiltBeacon.major.intValue)
        gravity = Double(tiltBeacon.minor.intValue) / 1000.0
        status = "Received data from Tilt"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "Location error: \(error.localizedDescription)"
    }
}
