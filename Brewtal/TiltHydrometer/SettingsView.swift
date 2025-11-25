//  SettingsView.swift
//  Brewtal
//
//  Created by Assistant on 11/24/25.
//
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var testResult: String? = nil
    @State private var isTesting = false
    @State private var testError: String? = nil
    
    var body: some View {
        Form {
            Section(header: Text("InfluxDB Credentials")) {
                TextField("Primary URL", text: $viewModel.url)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("Fallback URL", text: $viewModel.fallbackUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("Organization", text: $viewModel.org)
                TextField("Bucket", text: $viewModel.bucket)
                SecureField("API Token", text: $viewModel.token)
            }
            Section {
                Button("Test Connection") {
                    isTesting = true
                    testResult = nil
                    testError = nil
                    viewModel.testConnection { url, error in
                        DispatchQueue.main.async {
                            isTesting = false
                            if let url = url {
                                testResult = "Connected to: \(url)"
                                testError = nil
                            } else {
                                testResult = nil
                                testError = error?.localizedDescription ?? "Unknown error"
                            }
                        }
                    }
                }
                if isTesting {
                    ProgressView("Testing...")
                }
                if let result = testResult {
                    Label(result, systemImage: "checkmark.circle.fill").foregroundColor(.green)
                } else if let error = testError {
                    Label(error, systemImage: "xmark.octagon.fill").foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
