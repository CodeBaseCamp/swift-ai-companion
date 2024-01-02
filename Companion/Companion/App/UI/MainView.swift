// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import SwiftUI

private typealias ThisView = MainView

struct MainView: ModelView {
  enum Event: Hashable {
    case tapOnHistoryButton
    case tapOnChatCreationButton
    case queryViewEvent(QueryView.Event)
  }

  struct Model: Equatable {
    var chat: Chat
    var queryText: String
  }

  @ObservedObject
  private(set) var context: Context<Coeffects>

  private static let bottomViewID = UUID()

  var body: some View {
    ZStack {
      Color.defaultBackgroundColor
        .ignoresSafeArea()
      VStack(spacing: 0) {
        ZStack {
          Color.black
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
            .clipped()

          HStack(spacing: 0) {
            ActionButton(.sf_clock_arrow_circlepath, .tapOnHistoryButton)

            Spacer()

            Text(Self.companionName)
              .font(.companionTitleFont)
              .foregroundStyle(Color.white.opacity(0.9))

            Spacer()

            ActionButton(.sf_pencil_circle, .tapOnChatCreationButton)
          }
          .padding(.all, 10)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.all, 10)

        ScrollViewReader { scrollViewProxy in
          ScrollView {
            Spacer()
              .frame(height: 10)

            ForEach(self.model.chat.entries, id: \.id) { entry in
              ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                  .foregroundStyle(Color.chatEntryBackgroundColor)

                VStack(alignment: .leading, spacing: 0) {
                  VStack(alignment: .leading, spacing: 0) {
                    Text("You")
                      .font(.companionTitleFont)
                      .padding(.bottom, 5)

                    Text(entry.queryText)
                  }
                  .padding(.bottom, 30)

                  Text(Self.companionName)
                    .font(.companionTitleFont)
                    .padding(.bottom, 5)

                  HStack(alignment: .top, spacing: 0) {
                    ZStack {
                      RoundedRectangle(cornerRadius: 5)
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.gray)
                      Image(entry.symbol)
                    }
                    .padding(.trailing, 10)

                    switch entry.response {
                    case .failure:
                      Text("Failed handling query")
                    case let .text(status):
                      switch status {
                      case .ongoing:
                        Text("Loading...")
                      case let .result(result):
                        switch result {
                        case let .success(text):
                          Text(text)
                        case let .failure(error):
                          Text(error.humanReadableDescription)
                        }
                      }
                    case let .images(status):
                      switch status {
                      case .ongoing:
                        Text("Loading...")
                      case let .result(result):
                        switch result {
                        case let .success(image):
                          Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        case let .failure(error):
                          Text(error.humanReadableDescription)
                        }
                      }
                    }
                  }
                }
                .padding(.all, 10)
              }
              .padding(.horizontal, 10)
              .foregroundStyle(Color.chatEntryForegroundColor)

              if entry != self.model.chat.entries.last {
                Spacer()
                  .frame(height: 10)
              }
            }

            Spacer()
              .frame(height: 20)
              .id(Self.bottomViewID)
          }
          .foregroundStyle(Color.defaultForegroundColor)
          .onChange(of: self.model.chat) { oldValue, newValue in
            if oldValue.entries != newValue.entries {
              withAnimation {
                scrollViewProxy.scrollTo(Self.bottomViewID)
              }
            }
          }
        }

        QueryView(self.context(\.queryViewModel, Event.queryViewEvent))
      }
    }
  }
}

private extension ThisView.Model {
  var queryViewModel: QueryView.Model {
    return .init(text: self.queryText)
  }
}

private extension ThisView {
  static let companionName = "AI Companion"
}
