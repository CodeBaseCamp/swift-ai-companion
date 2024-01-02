// Copyright © Rouven Strauss. All rights reserved.

import Foundation

struct OpenAiChatResponse: Codable {
  struct Choice: Codable {
    struct Message: Codable {
      var role: String
      var content: String
    }
    
    var message: Message
  }

  var choices: [Choice]
}
