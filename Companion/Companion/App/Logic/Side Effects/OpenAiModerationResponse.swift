// Copyright © Rouven Strauss. All rights reserved.

import Foundation

struct OpenAiModerationResponse: Codable {
  struct Results: Codable {
    var flagged: Bool
  }

  var results: [Results]
}
