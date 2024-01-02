// Copyright © Rouven Strauss. All rights reserved.

import Foundation

struct OpenAiApiSettings: Codable, Hashable {
  var apiKey = ""
  var chatModel = Self.defaultChatModel
  var imageGenerationModel = Self.defaultImageGenerationModel
}

extension OpenAiApiSettings {
  static let defaultChatModel = "gpt-3.5-turbo-1106"
  static let defaultImageGenerationModel = "dall-e-3"
}
