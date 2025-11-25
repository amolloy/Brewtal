//  TiltHistoryView.swift
//  Brewtal
//
//  Created by Assistant on 11/24/25.
//

import SwiftUI
import InfluxDBSwift

struct TiltHistoryView: View {
    @StateObject private var settings = SettingsViewModel()
    
    @State private var client: InfluxDBClient?
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var connectionError: String?
    
    enum ConnectionStatus {
        case idle
        case connecting
        case connected
        case failed
        case missingCredentials
    }
    
    // Query parameters
    // TODO: Add UI to allow user selection
    private var timeRangeStart: String = "-2d"
    private var windowPeriod: String = "5m"

    // Dynamic queries based on settings
    private var gravityQuery: String {
        generateQuery(field: "gravity")
    }
    
    private var alcoholQuery: String {
        generateQuery(field: "alcohol_by_volume")
    }
    
    private var attenuationQuery: String {
        generateQuery(field: "apparent_attenuation")
    }
    
    private var temperatureQuery: String {
        generateQuery(field: "temp_fahrenheit")
    }
    
    private func generateQuery(field: String) -> String {
        // Use configured bucket or default to "pitch" if somehow empty
        let bucket = settings.bucket.isEmpty ? "pitch" : settings.bucket
        
		return """
		 from(bucket: "\(bucket)")
		 |> range(start: \(timeRangeStart))
		 |> filter(fn: (r) => r["_measurement"] == "tilt")
		 |> filter(fn: (r) => r["_field"] == "\(field)")
		 |> filter(fn: (r) => r["color"] == "black")
		 |> filter(fn: (r) => r["name"] == "black")
		 |> aggregateWindow(every: \(windowPeriod), fn: mean, createEmpty: false)
		 |> yield(name: "mean")
		 """
    }
    
    var body: some View {
        VStack(spacing: 0) {
            statusBar
            
            contentView
        }
        .navigationTitle("Tilt History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
        .onAppear(perform: checkAndConnect)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch connectionStatus {
        case .idle, .connecting:
            ProgressView("Connecting to InfluxDB...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .missingCredentials:
            VStack(spacing: 16) {
                Image(systemName: "gear.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text("InfluxDB Not Configured")
                    .font(.headline)
                Text("Please configure your InfluxDB credentials in settings.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                NavigationLink("Go to Settings", destination: SettingsView())
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .failed:
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                Text("Connection Failed")
                    .font(.headline)
                if let error = connectionError {
                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                Button("Retry Connection") {
                    checkAndConnect()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .connected:
            if let client = client {
                ScrollView {
                    VStack(spacing: 32) {
                        InfluxChartView(
                            title: "Specific Gravity",
                            client: client,
                            query: gravityQuery
                        )
                        InfluxChartView(
                            title: "Alcohol Content",
                            client: client,
                            query: alcoholQuery
                        )
                        InfluxChartView(
                            title: "Apparent Attenuation",
                            client: client,
                            query: attenuationQuery
                        )
                        InfluxChartView(
                            title: "Temperature",
                            client: client,
                            query: temperatureQuery
                        )
                    }.padding()
                }
            }
        }
    }
    
    private var statusBar: some View {
        HStack {
            Image(systemName: statusIcon)
            Text(statusMessage)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .foregroundColor(statusColor)
    }
    
    private var statusIcon: String {
        switch connectionStatus {
        case .connected: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .missingCredentials: return "gear.badge.questionmark"
        default: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch connectionStatus {
        case .connected: return .green
        case .failed: return .red
        case .connecting: return .blue
        case .missingCredentials: return .orange
        default: return .secondary
        }
    }
    
    private var statusMessage: String {
        switch connectionStatus {
        case .connected: return "Connected"
        case .failed: return "Connection Failed"
        case .connecting: return "Connecting..."
        case .missingCredentials: return "Setup Required"
        case .idle: return "Ready"
        }
    }
    
    private func checkAndConnect() {
        // Refresh settings from storage to ensure we have the latest if user came from SettingsView
        let url = UserDefaults.standard.string(forKey: "InfluxDBURL") ?? ""
        let token = KeychainHelper.loadString(key: "InfluxDBToken") ?? ""
        let org = UserDefaults.standard.string(forKey: "InfluxDBOrg") ?? ""
        let bucket = UserDefaults.standard.string(forKey: "InfluxDBBucket") ?? ""
        
        // Update local settings object so queries use the correct bucket
        settings.url = url
        settings.fallbackUrl = UserDefaults.standard.string(forKey: "InfluxDBFallbackURL") ?? ""
        settings.org = org
        settings.bucket = bucket
        settings.token = token
        
        if url.isEmpty || token.isEmpty || org.isEmpty || bucket.isEmpty {
            connectionStatus = .missingCredentials
            return
        }
        
        connectionStatus = .connecting
        connectionError = nil
        
        settings.testConnection { workingUrl, error in
            DispatchQueue.main.async {
                if let validUrl = workingUrl {
                    self.client = InfluxDBClient(
                        url: validUrl,
                        token: token,
                        options: InfluxDBClient.InfluxDBOptions(org: org)
                    )
                    self.connectionStatus = .connected
                } else {
                    self.connectionStatus = .failed
                    self.connectionError = error?.localizedDescription ?? "Could not connect to InfluxDB"
                }
            }
        }
    }
}

#Preview {
    TiltHistoryView()
}
