//
//  BluetoothViewModel.swift
//  Brewtal
//
//  Created by Andy Molloy on 11/24/25.
//

import Combine
import CoreBluetooth

class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
	@Published var status: String = "Initializing..."
	@Published var currentTemperatureFahrenheit: Double? = nil

	private var centralManager: CBCentralManager!
	private(set) var peripheral: CBPeripheral?
	private let targetDeviceName = "BrewVision Thermometer"

	private let brewVisionTempUUID = CBUUID(string: "FFA4")

	private var readableCharacteristics: [CBCharacteristic] = []

	override init() {
		super.init()
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}

	func startScanning() {
		guard centralManager.state == .poweredOn else {
			status = "Bluetooth is \(centralManager.state.rawValue)"
			return
		}
		status = "Scanning for \"\(targetDeviceName)\"..."
		centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
	}

	func connect(to peripheral: CBPeripheral) {
		status = "Connecting to \(peripheral.name ?? "device")..."
		centralManager.stopScan()
		self.peripheral = peripheral
		self.peripheral?.delegate = self
		centralManager.connect(peripheral, options: nil)
	}

	func readAllValues() {
		guard let peripheral = peripheral else { return }
		status = "Reading temperature..."
		for char in readableCharacteristics {
			if char.uuid == brewVisionTempUUID {
				peripheral.readValue(for: char)
			}
		}
	}

	private func parseBrewVisionData(characteristic: CBCharacteristic) -> Double? {
		guard characteristic.uuid == brewVisionTempUUID else {
			return nil
		}

		guard let data = characteristic.value, data.count >= 2 else {
			return nil
		}

		let wholePart = Double(data[0])
		let decimalPart = Double(data[1]) / 10.0

		let tempC = wholePart + decimalPart

		// Convert to Fahrenheit TODO: Make this an option?
		let tempF = (tempC * 1.8) + 32.0

		return tempF
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
			case .poweredOn:
				startScanning()
			case .poweredOff:
				status = "Bluetooth is off"
			case .unauthorized:
				status = "Bluetooth permission denied"
			default:
				status = "Bluetooth state: \(central.state.rawValue)"
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
		var peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String

		if peripheralName == nil {
			peripheralName = peripheral.name
		}

		guard let name = peripheralName else {
			return
		}

		if name.contains(targetDeviceName) {
			status = "Found \"\(name)\". Connecting..."
			connect(to: peripheral)
		}
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		status = "Successfully connected. Discovering services..."
		peripheral.discoverServices(nil)
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		status = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		status = "Disconnected. Re-scanning..."
		self.peripheral = nil
		self.currentTemperatureFahrenheit = nil
		self.readableCharacteristics.removeAll()
		startScanning()
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		if let error = error {
			status = "Service discovery failed: \(error.localizedDescription)"
			return
		}

		guard let services = peripheral.services else { return }
		status = "Found \(services.count) service(s). Discovering characteristics..."

		for service in services {
			peripheral.discoverCharacteristics(nil, for: service)
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if let error = error {
			status = "Characteristic discovery failed: \(error.localizedDescription)"
			return
		}

		guard let characteristics = service.characteristics else { return }

		for char in characteristics {
			if char.properties.contains(.notify) {
				peripheral.setNotifyValue(true, for: char)
			}

			if char.properties.contains(.read) {
				readableCharacteristics.append(char)
			}

			if char.uuid == brewVisionTempUUID {
				status = "Found temp characteristic. Reading..."
				peripheral.readValue(for: char)
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if let error = error {
			status = "Data update failed: \(error.localizedDescription)"
			return
		}

		if let tempF = parseBrewVisionData(characteristic: characteristic) {
			DispatchQueue.main.async {
				self.currentTemperatureFahrenheit = tempF
				self.status = "Updated: \(Date().formatted(date: .omitted, time: .standard))"
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		if let error = error {
			status = "Failed to subscribe: \(error.localizedDescription)"
		}
	}
}
