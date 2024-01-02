// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

struct AppState: Equatable {
  var ephemeralState: EphemeralState = .init()

  var chats: [Chat] = [.init()]

  var openAiApiSettings: OpenAiApiSettings = .init()

  /// Kind of the update which led to the current state of this instance.
  var updateKind: UpdateKind = .permanent
}

extension AppState {
  var currentChat: Chat {
    get {
      return self.chats[self.ephemeralState.indexOfCurrentChat]
    }
    set {
      self.chats[self.ephemeralState.indexOfCurrentChat] = newValue
    }
  }
}

extension AppState: StateProtocol {
  enum CodingKeys: String, CodingKey {
    case openAiApiSettings
    case chats
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.ephemeralState = .init()
    self.openAiApiSettings =
      (try? container.decode(OpenAiApiSettings.self, forKey: .openAiApiSettings)) ?? .init()
    self.chats = (try? container.decode(
      Array<Chat>.self,
      forKey: .chats)
    ) ?? []
    self.updateKind = .permanent
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.chats, forKey: .chats)
    try container.encode(self.openAiApiSettings, forKey: .openAiApiSettings)
  }

  static func instance(from data: Data) throws -> Self {
    return try JSONDecoder().decode(Self.self, from: data)
  }

  func data() throws -> Data {
    return try JSONEncoder().encode(self)
  }
}

private extension String {
  var uint8Representation: [UInt8] {
    return self.utf8CString.map { UInt8($0) }
  }
}
