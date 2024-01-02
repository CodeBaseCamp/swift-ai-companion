// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation
import SwiftUI

final class App {
  /// Object responsible for the major part of the app logic.
  private let logicModule: Companion.LogicModule

  private(set) var view: AppView

  private var observerReferences: [Any] = []

  init(
    with coeffects: Coeffects,
    model: Companion.Model,
    sideEffectPerformer: SideEffectPerformer
  ) {
    do {
      try model.load(from: .standard, forKey: Companion.dataStorageKey)
    } catch {}

    let logicModule = LogicModule(
      model: model,
      sideEffectPerformer: sideEffectPerformer,
      coeffects: coeffects,
      staticObservers: []
    )

    self.logicModule = logicModule

    let ((view, viewObserver), _) =
      Self.appView(observing: model, logicModule: logicModule, coeffects: coeffects)
    self.view = view

    self.observerReferences = Companion.referencesOfObservers(
      addedTo: logicModule,
      observing: model,
      using: coeffects
    ) + ([viewObserver] as [Any])
  }

  private static func appView(
    observing model: Companion.Model,
    logicModule: Companion.LogicModule,
    coeffects: Coeffects
  ) -> ((AppView, ModelViewObservers), Companion.UILogic<AppView.Event>) {
    let logic = Companion.appViewLogic(logicModule)

    return (AppView.instance(observing: \.self, of: model, using: coeffects) { event in
      logic.handle(event, given: model.state)
    }, logic)
  }
}

extension Companion.Model {
  func requestClosure(_ coeffects: Coeffects) -> (Request) -> Void {
    return { requests in
      self.handleInSingleTransaction(requests, using: coeffects)
    }
  }
}
