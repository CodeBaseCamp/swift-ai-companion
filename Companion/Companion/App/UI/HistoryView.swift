// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import SwiftUI

private typealias ThisView = HistoryView

struct HistoryView: ModelView {
  enum Event: Hashable {
    case tapOnSettingsButton
    case tapOnEntry(entryID: UUID)
    case tapOnFavoriteButtonOfEntry(entryID: UUID)
  }

  struct Model: Equatable {
    var entries: [Chat]
  }

  let context: Context<Coeffects>

  var body: some View {
    ZStack {
      Color.popoverViewBackgroundColor

      VStack(spacing: 0) {
        HStack(alignment: .center, spacing: 0) {
          ActionButton(.sf_gear, .tapOnSettingsButton, scaleFactor: 0.8)

          Spacer()

          Text("History")
            .font(.companionTitleFont)
            .foregroundColor(.historyViewForeroundColor)

          Spacer()

          Spacer()
            .frame(width: .minimumButtonDimension, height: .minimumButtonDimension)
        }
        .padding(.bottom, 20)

        ScrollView {
          ForEach(self.model.chatInfo, id: \.self) { info in
            ZStack {
              Color.historyViewEntryBackgroundColor

              HStack(spacing: 0) {
                ARTButton(.tapOnEntry(entryID: info.id)) {
                  HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                      RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(.white)
                      Text(info.dateString)
                        .font(.footnote)
                        .foregroundStyle(Color.historyViewEntryForegroundColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    }
                    .fixedSize()
                    Spacer()
                      .frame(width: 10)
                    Text(info.title)
                      .foregroundStyle(Color.historyViewEntryForegroundColor)
                  }
                }

                Spacer()

                ActionButton(
                  .sf_star_fill,
                  .tapOnFavoriteButtonOfEntry(entryID: info.id),
                  symbolOpacity: info.symbolOpacity
                )
              }
              .padding(.all, 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .clipped()
          }
        }
      }
      .padding(.init(top: 20, leading: 10, bottom: 20, trailing: 10))
    }
  }
}

private extension ThisView.Model {
  struct ChatInfo: Hashable {
    var id: UUID
    var dateString: String
    var title: String
    var symbolOpacity: CGFloat
  }
  
  var chatInfo: [ChatInfo] {
    let formatter = make(DateFormatter()) {
      $0.dateStyle = .short
    }
    
    return self.entries.sorted(by: { $0.modificationDate > $1.modificationDate }).map {
      ChatInfo(
        id: $0.id,
        dateString: formatter.string(from: $0.creationDate),
        title: $0.entries.first?.queryText ?? "Current chat",
        symbolOpacity: $0.isFavorite ? 1 : 0.3
      )
    }
  }
}
