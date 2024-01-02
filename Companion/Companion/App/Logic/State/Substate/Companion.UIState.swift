// Copyright © Rouven Strauss. All rights reserved.

import Foundation
import SwiftUI

extension EphemeralState {
  struct UIState: Hashable {
    var uiUpdateID: UUID = .init()
    var displayedPopoverView: PopoverViewKind = .none
  }
}

enum PopoverViewKind: Hashable {
  case none
  case historyView
  case settingsView
}
