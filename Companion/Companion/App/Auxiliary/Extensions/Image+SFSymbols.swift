// Copyright © Rouven Strauss. All rights reserved.

import SFSymbols

import SwiftUI

extension Image {
  init(_ symbol: SFSymbol) {
    self.init(systemName: symbol.systemName)
  }
}

extension SFSymbol {
  var systemName: String {
    return self.rawValue
      .replacingOccurrences(of: "sf_", with: "")
      .replacingOccurrences(of: "_", with: ".")
  }
}
