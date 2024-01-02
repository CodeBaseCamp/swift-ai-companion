// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

enum SideEffect: Hashable {
  enum API: Hashable {
    case openAi(OpenAiApiSettings)
  }

  case textGeneration(forPrompt: String, api: API, entryID: UUID)
  case imageGeneration(forPrompt: String, dimension: UInt, api: API, entryID: UUID)
}

extension SideEffect: SideEffectProtocol {
  var humanReadableDescription: String {
    switch self {
    case let .textGeneration(prompt, api, entryID):
      return """
        text generation for prompt \(prompt)
        API: \(api.humanReadableDescription)
        entryID: \(entryID)
        """
    case let .imageGeneration(prompt, dimension, api, entryID):
      return """
        image generation for prompt \(prompt)
        dimension: \(dimension)
        API: \(api.humanReadableDescription)
        entryID: \(entryID)
        """
    }
  }
}

extension SideEffect.API: SideEffectProtocol {
  var humanReadableDescription: String {
    switch self {
    case .openAi:
      return "OpenAI"
    }
  }
}
