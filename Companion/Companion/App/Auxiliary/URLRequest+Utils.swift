// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

public extension URLRequest {
  static func postRequest(_ url: URL, apiKey: String, jsonObject: [String: Any]) -> Self {
    return make(URLRequest(url: url)) {
      $0.addValue("application/json", forHTTPHeaderField: "Content-Type")
      $0.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
      $0.httpMethod = "POST"
      $0.httpBody = requiredLet(
        try? JSONSerialization.data(withJSONObject: jsonObject),
        "Invalid json object: \(jsonObject)"
      )
    }
  }
}
