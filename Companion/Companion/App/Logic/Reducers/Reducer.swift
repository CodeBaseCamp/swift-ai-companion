// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

extension Companion {
  static let reducer = Reducer<
    AppState,
    Request,
    Coeffects
  > { state, requests, coeffects in
    state.executePerformingFollowUpOperations(for: requests) { state in
      requests.forEach { request in
        Self.update(&state, accordingTo: request, using: coeffects)
      }
    }
  }

  private static func update(_ state: inout AppState,
                             accordingTo request: Request,
                             using coeffects: Coeffects) {
    switch request {
    case let .updateOfOpenAiApiSettings(settings):
      state.openAiApiSettings = settings
    case .uiUpdateIDChangeRequest:
      state.ephemeralState.uiState.uiUpdateID = coeffects.default.newUUID()
    case let .updateOfQueryText(text):
      state.ephemeralState.queryText = text
    case .showingOfHistoryView:
      state.ephemeralState.uiState.displayedPopoverView = .historyView
    case .togglingOfPopoverView:
      state.ephemeralState.uiState.displayedPopoverView = 
        state.ephemeralState.uiState.displayedPopoverView == .historyView ?
        .settingsView : .historyView
    case .hidingOfPopoverView:
      state.ephemeralState.uiState.displayedPopoverView = .none
    case .creationOfNewChat:
      state.chats.removeAll { $0.entries.isEmpty }
      state.chats.append(.init())
      state.ephemeralState.indexOfCurrentChat = state.chats.count - 1
    case let .appendingOfEntry(entry):
      state.currentChat.entries.append(entry)
      state.ephemeralState.queryText = ""
    case let .finalizingOfEntry(entryID, response):
      guard let chatIndex =
              state.chats.firstIndex(where: { $0.entries.contains { entry in entry.id == entryID }})
      else {
        return
      }

      state.chats[chatIndex].entries  = state.chats[chatIndex].entries.map { entry in
        return entry.id == entryID ? copied(entry) {
          switch response {
          case .failure:
            $0.response = .failure
          case let .text(text):
            $0.response = .text(.result(.success(text)))
          case let .images(images):
            $0.response = .images(.result(.success(images[0])))
          }
        } : entry
      }
    case let .displayOfEntry(entryID):
      state.ephemeralState.indexOfCurrentChat =
        requiredLet(state.chats.firstIndex { $0.id == entryID }, "Must exist")
      state.ephemeralState.uiState.displayedPopoverView = .none
      state.ephemeralState.queryText = ""
    case let .togglingOfFavoriteSetting(entryID):
      let index =
        requiredLet(state.chats.firstIndex { $0.id == entryID }, "Must exist")
      state.chats[index].isFavorite.toggle()
    }
  }
}

private extension AppState {
  mutating func executePerformingFollowUpOperations(
    for _: [Request],
    _ closure: (inout Self) -> Void
  ) {
    var previousState = self

    closure(&self)

    previousState.ephemeralState = self.ephemeralState

    self.updateKind = previousState == self ? .ephemeral : .permanent
  }
}
