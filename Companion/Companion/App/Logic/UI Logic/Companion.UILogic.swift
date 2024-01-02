// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

extension Companion {
  static func appViewLogic(_ module: LogicModule) -> UILogic<AppView.Event> {
    return module.viewLogic { event, state, then, _ in
      switch event {
      case let .mainViewEvent(event):
        switch event {
        case .tapOnHistoryButton:
          then.handle(.showingOfHistoryView)

        case .tapOnChatCreationButton:
          then.handle(.creationOfNewChat)

        case let .queryViewEvent(event):
          switch event {
          case let .updateOfQueryText(text):
            then.handle(.updateOfQueryText(text))

          case let .tapOnButton(button):
            let entry: Chat.Entry
            let sideEffect: SideEffect

            switch button {
            case .text:
              entry = Chat.Entry(
                queryText: state.ephemeralState.queryText,
                response: .text(.ongoing)
              )
              sideEffect = .textGeneration(
                forPrompt: state.ephemeralState.queryText,
                api: .openAi(state.openAiApiSettings),
                entryID: entry.id
              )
            case .images:
              entry = Chat.Entry(
                queryText: state.ephemeralState.queryText,
                response: .images(.ongoing)
              )
              sideEffect = .imageGeneration(
                forPrompt: state.ephemeralState.queryText,
                dimension: 1024,
                api: .openAi(state.openAiApiSettings),
                entryID: entry.id
              )
            }

            then.handle(.appendingOfEntry(entry))
            then.perform(.only(sideEffect, on: .backgroundThread(.defaultInstance))) {
              if $0.isFailure {
                then.handle(.finalizingOfEntry(withID: entry.id, .failure))
              }
            }
          }
        }

      case let .popoverViewEvent(event):
        switch event {
        case let .historyViewEvent(event):
          switch event {
          case .tapOnSettingsButton:
            then.handle(.togglingOfPopoverView)

          case let .tapOnEntry(entryID):
            then.handle(.displayOfEntry(entryID: entryID))

          case let .tapOnFavoriteButtonOfEntry(entryID):
            then.handle(.togglingOfFavoriteSetting(entryID: entryID))
          }

        case let .settingsViewEvent(event):
          let requests: [Request]

          switch event {
          case .tapOnCloseButton:
            requests = [.togglingOfPopoverView]
          case let .tapOnSaveButton(openAiApiSettings):
            requests = [
              .updateOfOpenAiApiSettings(openAiApiSettings),
              .togglingOfPopoverView
            ]
          }

          then.handleInSingleTransaction(requests)
        }

      case .dismissalOfPopoverView:
        then.handle(.hidingOfPopoverView)
      }
    } shouldHandle: { event, _ in
      return true
    }
  }
}
