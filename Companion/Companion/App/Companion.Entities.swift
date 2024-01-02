// Copyright © Rouven Strauss. All rights reserved.

import ART

// MARK: Structs

enum BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol {
  case defaultInstance
}

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
    ART.CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>
  typealias Executable = ART.Executable<Request, SideEffect, Error, BackgroundDispatchQueueID>
  typealias LogicModule = ART.LogicModule<
    AppState,
    Request,
    SideEffectPerformer
  >

  typealias UILogic<ViewEvent: Equatable> =
    UIEventLogicModule<ViewEvent, AppState, Request, SideEffectPerformer>
}
