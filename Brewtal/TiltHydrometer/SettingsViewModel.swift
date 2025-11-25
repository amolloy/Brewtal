//  SettingsViewModel.swift
//  Brewtal
//
//  Created by Assistant on 11/24/25.
//
import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var url: String {
        didSet { UserDefaults.standard.setValue(url, forKey: "InfluxDBURL") }
    }
    @Published var fallbackUrl: String {
        didSet { UserDefaults.standard.setValue(fallbackUrl, forKey: "InfluxDBFallbackURL") }
    }
    @Published var org: String {
        didSet { UserDefaults.standard.setValue(org, forKey: "InfluxDBOrg") }
    }
    @Published var bucket: String {
        didSet { UserDefaults.standard.setValue(bucket, forKey: "InfluxDBBucket") }
    }
    @Published var token: String {
        didSet { _ = KeychainHelper.saveString(key: "InfluxDBToken", value: token) }
    }
    
    init() {
        self.url = UserDefaults.standard.string(forKey: "InfluxDBURL") ?? ""
        self.fallbackUrl = UserDefaults.standard.string(forKey: "InfluxDBFallbackURL") ?? ""
        self.org = UserDefaults.standard.string(forKey: "InfluxDBOrg") ?? ""
        self.bucket = UserDefaults.standard.string(forKey: "InfluxDBBucket") ?? ""
        self.token = KeychainHelper.loadString(key: "InfluxDBToken") ?? ""
    }
    
    /// Attempts a network request to main URL, falls back to secondary if failure. Returns the working URL or nil.
    func testConnection(completion: @escaping (String?, Error?) -> Void) {
        // Dummy endpoint for test
        func tryUrl(_ urlString: String, next: @escaping () -> Void) {
            guard let url = URL(string: urlString) else { next(); return }
            var req = URLRequest(url: url)
            req.timeoutInterval = 5
            let task = URLSession.shared.dataTask(with: req) { _, response, error in
                if let _ = error {
                    next()
                } else if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                    completion(url.absoluteString, nil)
                } else {
                    next()
                }
            }
            task.resume()
        }
        tryUrl(url) { [weak self] in
            guard let fallback = self?.fallbackUrl, !fallback.isEmpty else {
                completion(nil, NSError(domain: "NoWorkingURL", code: 1))
                return
            }
            tryUrl(fallback) {
                completion(nil, NSError(domain: "NoWorkingURL", code: 2))
            }
        }
    }
}

