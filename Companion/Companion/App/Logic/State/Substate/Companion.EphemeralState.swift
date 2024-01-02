// Copyright © Rouven Strauss. All rights reserved.

import Foundation
import SwiftUI

struct EphemeralState: Equatable {
  var uiState: UIState = .init()

  var queryText: String = ""

  var indexOfCurrentChat = 0
}
