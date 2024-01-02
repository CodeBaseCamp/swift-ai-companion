// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import Foundation
import SwiftUI

struct Chat: Codable, Equatable {
  var id: UUID = .init()
  var creationDate: Date = .now
  var modificationDate: Date = .now
  var entries: [Entry] = []
  var isFavorite: Bool = false
}

extension Chat {
  struct Entry: Codable, Equatable {
    enum Response: Equatable {
      enum Status<T: Equatable>: Equatable {
        case ongoing
        case result(Result<T, Companion.Error>)
      }

      case failure
      case text(Status<String>)
      case images(Status<UIImage>)
    }

    var id: UUID = .init()
    var queryText: String
    var response: Response
    var creationDate: Date = .now
  }
}

extension Chat.Entry.Response: Codable {
  enum CodingKeys: String, CodingKey {
    case text
    case imageData
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if
      let data = try? container.decode(Data.self, forKey: .imageData)
    {
      if let image = UIImage(data: data) {
        self = .images(.result(.success(image)))
      } else {
        self = .images(.result(.failure(.imageDataDecoding)))
      }
    } else {
      if let text = try? container.decode(String.self, forKey: .text) {
        self = .text(.result(.success(text)))
      } else {
        self = .text(.result(.failure(.textDecoding)))
      }
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case let .text(.result(.success(text))):
      try container.encode(text, forKey: .text)
    case let .images(.result(.success(image))):
      try container.encode(image.heicData(), forKey: .imageData)
    case .failure, .text, .images:
      break
    }
  }
}

extension Chat.Entry {
  var symbol: SFSymbol {
    switch self.response {
    case .failure:
      return .sf_x_circle_fill
    case .text:
      return EntryType.text.symbol
    case .images:
      return EntryType.images.symbol
    }
  }
}
