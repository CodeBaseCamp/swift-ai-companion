// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import SwiftUI

extension ModelView where Coeffects == Coeffects {
  func ActionButton(
    _ symbol: SFSymbol,
    _ event: Event,
    symbolOpacity: CGFloat = 1,
    scaleFactor: CGFloat = 1
  ) -> some View {
    return ARTButton(event) {
      ZStack {
        Color.white
          .foregroundColor(Color.defaultBackgroundColor)
          .background(Color.buttonBackgroundColor)
          .clipShape(Circle())

        Image(symbol)
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(Color.buttonForegroundColor)
          .opacity(symbolOpacity)
      }
      .scaleEffect(CGSize(width: scaleFactor, height: scaleFactor))
      .frame(width: .minimumButtonDimension, height: .minimumButtonDimension)
    }
  }
}
