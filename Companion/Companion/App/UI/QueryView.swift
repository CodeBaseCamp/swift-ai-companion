// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import SwiftUI

private typealias ThisView = QueryView

struct QueryView: ModelView {
  enum Event: Hashable {
    case updateOfQueryText(String)
    case tapOnButton(EntryType)
  }

  struct Model: Equatable {
    var text: String
  }

  @ObservedObject
  private(set) var context: Context<Coeffects>

  private let textBinding: Binding<String>

  init(context: Context<Coeffects>) {
    self.context = context
    self.textBinding = context.binding(\.text) { .updateOfQueryText($0) }
  }

  var body: some View {
    HStack(spacing: 0) {
      Companion.TextField(
        placeholderText: "Write your prompt here",
        binding: self.textBinding,
        shouldAutocorrect: true
      )

      VStack(spacing: 0) {
        ForEach(EntryType.allCases, id: \.self) { entryType in
          ActionButton(entryType.symbol, .tapOnButton(entryType))

          if entryType != EntryType.allCases.last {
            Spacer()
              .frame(height: 10)
          }
        }
      }
      .opacity(self.model.buttonOpacity)
    }
    .padding(.all, 10)
    .background(
      RoundedRectangle(cornerRadius: 30)
        .foregroundStyle(Color.black)
    )
    .padding(.horizontal, 10)
  }
}

private extension ThisView.Model {
  var buttonOpacity: CGFloat {
    return self.text.isEmpty ? 0.2 : 1
  }
}
