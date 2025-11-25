//  InfluxChartView.swift
//  Brewtal
//
//  Created by Assistant on 11/24/25.
//
import SwiftUI
import Charts
import InfluxDBSwift

// Simple point model for mapping influx data
struct BasicInfluxPoint: Identifiable, Hashable {
    let id = UUID()
    let time: Date
    let value: Double
    
    static func fromRecords(_ records: [QueryAPI.FluxRecord]) -> [BasicInfluxPoint] {
        records.compactMap { rec in
            // Always map from "_value" as requested
            guard let date = rec.values["_time"] as? Date,
                  let val = rec.values["_value"] as? Double else { return nil }
            return BasicInfluxPoint(time: date, value: val)
        }
    }
}

struct InfluxChartView: View {
    let title: String
    let client: InfluxDBClient
    let query: String
    
    @State private var isLoading = true
    @State private var data: [BasicInfluxPoint] = []
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            if isLoading {
                ProgressView()
            } else if let error = error {
                Text("Error: \(error.localizedDescription)").foregroundColor(.red)
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Value", point.value)
                    )
                }
                .frame(height: 200)
            }
        }
        .padding(.vertical)
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        error = nil
        do {
            let cursor = try await client.queryAPI.query(query: query)
            var records = [QueryAPI.FluxRecord]()
            
            while let record = try cursor.next() {
                records.append(record)
            }
            
            let mapped = BasicInfluxPoint.fromRecords(records)

            await MainActor.run {
                self.data = mapped
                self.isLoading = false
            }
        } catch {
            print("[\(title)] Query error: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
