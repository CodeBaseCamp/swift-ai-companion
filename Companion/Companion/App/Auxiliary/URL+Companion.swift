// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

extension URL {
  static let openAiModerationsURL =
    requiredLet(Self(string: "https://api.openai.com/v1/moderations"), "Must be creatable")
  static let openAiChatURL =
    requiredLet(Self(string: "https://api.openai.com/v1/chat/completions"), "Must be creatable")
  static let openAiImageGenerationURL =
    requiredLet(Self(string: "https://api.openai.com/v1/images/generations"), "Must be creatable")
}
