// Copyright © Rouven Strauss. All rights reserved.

import ART

// MARK: Structs

struct Coeffects: CoeffectsProtocol {
  let defaultCoeffects: DefaultCoeffectsProtocol = DefaultCoeffects()

  var `default`: DefaultCoeffectsProtocol {
    return self.defaultCoeffects
  }
}

// MARK: Typealiases

extension Companion {
  typealias Model = LogicModule.Model
  typealias CompositeSideEffect = 
    TaskBasedCompositeSideEffect<SideEffect, SideEffectError>
  typealias Executable = TaskBasedExecutable<Request, SideEffect, Error>
  typealias LogicModule = TaskBasedLogicModule<
    AppState,
    Request,
    SideEffectPerformer
  >

  typealias UILogic<ViewEvent: Equatable> =
    TaskBasedUIEventLogicModule<ViewEvent, AppState, Request, SideEffectPerformer>
}
