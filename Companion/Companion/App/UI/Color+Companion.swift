// Copyright © Rouven Strauss. All rights reserved.

import SwiftUI

extension Color {
  private static let defaultHue: CGFloat = 0
  private static let defaultSaturation: CGFloat = 0

  // MARK: General

  static let defaultBackgroundColor =
    Self(hue: Self.defaultHue, saturation: Self.defaultSaturation, brightness: 0.25)
  static let defaultForegroundColor: Self = .white

  static let chatEntryBackgroundColor =
    Self(hue: Self.defaultHue, saturation: Self.defaultSaturation, brightness: 0.3)
  static let chatEntryForegroundColor: Self = .white

  // MARK: History

  static let popoverViewBackgroundColor =
    Self(hue: Self.defaultHue, saturation: Self.defaultSaturation, brightness: 0.15)

  static let historyViewForeroundColor = Color.white.opacity(0.9)
  static let historyViewEntryBackgroundColor =
    Self(hue: Self.defaultHue, saturation: Self.defaultSaturation, brightness: 0.5)
  static let historyViewEntryForegroundColor: Self = .black

  // MARK: Buttons

  static let buttonBackgroundColor: Self = .white
  static let buttonForegroundColor: Self = .black
}

extension Font {
  static let companionBodyFont: Self = .custom("Avenir Next", size: 14)
  static let companionApiFont: Self = .custom("Avenir Next", size: 11)
  static let companionTitleFont: Self = .custom("Avenir Next Bold", size: 18)
}
