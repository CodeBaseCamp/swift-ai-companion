// Copyright © Rouven Strauss. All rights reserved.

import ART

import Combine
import Foundation
import SwiftUI

private typealias ThisView = AppView

struct AppViewModel: ViewModel {
  var id: UUID

  var mainViewModel: MainView.Model

  var popoverViewModel: PopoverView.Model

  var displayedPopoverView: PopoverViewKind

  // MARK: ViewModel

  static func makeInstance(from state: AppState?) -> Self {
    let state = requiredLet(state, "State must exist")
    let popoverViewModel: PopoverView.Model.ViewModel =
      state.ephemeralState.uiState.displayedPopoverView == .historyView ?
      .historyViewModel(.init(entries: state.chats)) :
      .settingsViewModel(.init(openAiApiSettings: state.openAiApiSettings))

    return Self(
      id: state.ephemeralState.uiState.uiUpdateID,
      mainViewModel: .init(chat: state.currentChat, queryText: state.ephemeralState.queryText),
      popoverViewModel: .init(viewModel: popoverViewModel),
      displayedPopoverView: state.ephemeralState.uiState.displayedPopoverView
    )
  }
}

struct AppView: ModelView {
  enum Event: Hashable {

    case mainViewEvent(MainView.Event)
    case popoverViewEvent(PopoverView.Event)
    case dismissalOfPopoverView
  }

  @ObservedObject
  private(set) var context: ViewContext<AppViewModel, Event, Coeffects>

  init(context: ViewContext<AppViewModel, Event, Coeffects>) {
    self.context = context
  }

  var body: some View {
    MainView(self.context(\.mainViewModel, Event.mainViewEvent))
    .popover(isPresented: self.context.immutableBinding(\.shouldShowPopoverView)) {
      PopoverView(self.context(\.popoverViewModel, Event.popoverViewEvent))
        .ignoresSafeArea()
        .onDisappear {
          self.handle(.dismissalOfPopoverView)
        }
    }
  }
}

extension AppViewModel {
  var shouldShowPopoverView: Bool {
    switch self.displayedPopoverView {
    case .none:
      return false
    case .historyView, .settingsView:
      return true
    }
  }
}

struct CompanionAppView_Preview: PreviewProvider {
  static var observer: Any?

  static var previews: some View {
    let initialAppState = AppState()

    let (appView, observer) = ThisView.instance(
      observing: \AppState.self,
      of: Companion.Model(state: initialAppState, reduce: { _, _, _ in }),
      using: Coeffects(),
      handlingEventsWith: { _ in }
    )
    self.observer = observer
    return appView
  }
}
