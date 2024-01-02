// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import SwiftUI

private typealias ThisView = PopoverView

struct PopoverView: ModelView {
  enum Event: Hashable {
    case historyViewEvent(HistoryView.Event)
    case settingsViewEvent(SettingsView.Event)
  }

  struct Model: Equatable {
    enum ViewModel: Equatable {
      case historyViewModel(HistoryView.Model)
      case settingsViewModel(SettingsView.Model)
    }

    var viewModel: ViewModel
  }

  @ObservedObject
  private(set) var context: Context<Coeffects>

  var body: some View {
    ZStack {
      ConditionalView(self.context(\.historyViewModel, Event.historyViewEvent)) {
        HistoryView($0)
      }
      ConditionalView(self.context(\.settingsViewModel, Event.settingsViewEvent)) {
        SettingsView($0)
      }
    }
  }
}

private extension ThisView.Model {
  var historyViewModel: HistoryView.Model? {
    switch self.viewModel {
    case let .historyViewModel(model):
      return model
    case .settingsViewModel:
      return nil
    }
  }

  var settingsViewModel: SettingsView.Model? {
    switch self.viewModel {
    case let .settingsViewModel(model):
      return model
    case .historyViewModel:
      return nil
    }
  }
}
