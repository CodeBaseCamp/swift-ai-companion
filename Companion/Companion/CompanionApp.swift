// Copyright © Rouven Strauss. All rights reserved.

import SwiftUI
import ART

enum Companion {}

@main
struct CompanionApp: SwiftUI.App {
  let app = {
    let coeffects = Coeffects()
    let model = Model(state: .init(), reduce: Companion.reducer.reduce)
    return App(
      with: coeffects,
      model: model,
      sideEffectPerformer: .productionInstance(model.requestClosure(coeffects))
    )
  }()

  var body: some Scene {
    WindowGroup {
      self.app.view
    }
  }
}
