// Copyright © Rouven Strauss. All rights reserved.

import SFSymbols

enum EntryType: CaseIterable, Codable, Hashable {
  case text
  case images
}

extension EntryType {
  var symbol: SFSymbol {
    switch self {
    case .text:
      return .sf_text_alignleft
    case .images:
      return .sf_photo_circle_fill
    }
  }
}
