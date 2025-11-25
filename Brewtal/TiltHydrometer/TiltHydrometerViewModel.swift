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
    enum TiltColor: String, CaseIterable {
        case black
        case red
        case green
        case yellow
        case pink
        case blue
        case purple
        case orange
        
        var uuid: UUID {
            switch self {
            case .black:
                return UUID(uuidString: "a495bb10-c5b1-4b44-b512-1370f02d74de")!
            case .red:
                return UUID(uuidString: "a495bb20-c5b1-4b44-b512-1370f02d74de")!
            case .green:
                return UUID(uuidString: "a495bb30-c5b1-4b44-b512-1370f02d74de")!
            case .yellow:
                return UUID(uuidString: "a495bb40-c5b1-4b44-b512-1370f02d74de")!
            case .pink:
                return UUID(uuidString: "a495bb50-c5b1-4b44-b512-1370f02d74de")!
            case .blue:
                return UUID(uuidString: "a495bb60-c5b1-4b44-b512-1370f02d74de")!
            case .purple:
                return UUID(uuidString: "a495bb70-c5b1-4b44-b512-1370f02d74de")!
            case .orange:
                return UUID(uuidString: "a495bb80-c5b1-4b44-b512-1370f02d74de")!
            }
        }
        
        static let allColors: [TiltColor] = [.black, .red, .green, .yellow, .pink, .blue, .purple, .orange]
    }
    
    @Published var temperature: Double? = nil
    @Published var gravity: Double? = nil
    @Published var status: String = "Initializing..."
    
    private var centralManager: CBCentralManager!
    private var locationManager: CLLocationManager!
    
    private let selectedColorKey = "SelectedTiltColor"
    
    var selectedColor: TiltColor {
        get {
            if let stored = UserDefaults.standard.string(forKey: selectedColorKey),
               let color = TiltColor(rawValue: stored) {
                return color
            }
            return .green // default color
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: selectedColorKey)
            startScanningForBeacons()
        }
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func setSelectedColor(_ color: TiltColor) {
        selectedColor = color
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
        locationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: selectedColor.uuid))
        let beaconRegion = CLBeaconRegion(uuid: selectedColor.uuid, identifier: "Tilt")
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
