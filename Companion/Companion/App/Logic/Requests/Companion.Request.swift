// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation
import SwiftUI

enum Request: RequestProtocol, Equatable {
  enum ApiResponse: Equatable {
    case failure
    case text(String)
    case images([UIImage])
  }

  case updateOfOpenAiApiSettings(OpenAiApiSettings)

  case uiUpdateIDChangeRequest
  case updateOfQueryText(String)
  case showingOfHistoryView
  case togglingOfPopoverView
  case hidingOfPopoverView

  case creationOfNewChat
  case appendingOfEntry(Chat.Entry)
  case finalizingOfEntry(withID: UUID, ApiResponse)
  case displayOfEntry(entryID: UUID)
  case togglingOfFavoriteSetting(entryID: UUID)
}

enum UpdateKind: Hashable {
  case ephemeral
  case permanent
}

extension Request {
  func mustResultInChange() -> Bool {
    switch self {
    case .uiUpdateIDChangeRequest,
         .creationOfNewChat,
         .appendingOfEntry,
         .finalizingOfEntry,
         .togglingOfFavoriteSetting:
      return true
    case .updateOfOpenAiApiSettings,
         .updateOfQueryText,
         .showingOfHistoryView,
         .togglingOfPopoverView,
         .hidingOfPopoverView,
         .displayOfEntry:
      return false
    }
  }
}

extension Request: HumanReadable {
  var humanReadableDescription: String {
    switch self {
    case .updateOfOpenAiApiSettings:
      return "update of Open AI API settings"
    case .uiUpdateIDChangeRequest:
      return "UI update ID change request"
    case .updateOfQueryText:
      return "update of text"
    case .showingOfHistoryView:
      return "showing of history view"
    case .togglingOfPopoverView:
      return "showing of settings view"
    case .hidingOfPopoverView:
      return "hiding of popover view"
    case .creationOfNewChat:
      return "creation of new chat"
    case .appendingOfEntry:
      return "appending of new entry"
    case let .finalizingOfEntry(entryID, response):
      return "finalizing of entry with ID \(entryID.uuidString) using response " +
        response.humanReadableDescription
    case let .displayOfEntry(entryID):
      return "display of entry with ID \(entryID.uuidString)"
    case let .togglingOfFavoriteSetting(entryID):
      return "toggling of favorite setting of entry with ID \(entryID.uuidString)"
    }
  }
}

extension Request.ApiResponse: HumanReadable {
  var humanReadableDescription: String {
    switch self {
    case .failure:
      return "failure"
    case .text:
      return "text"
    case .images:
      return "images"
    }
  }
}
