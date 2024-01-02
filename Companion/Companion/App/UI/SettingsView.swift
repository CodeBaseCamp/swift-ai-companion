// Copyright © Rouven Strauss. All rights reserved.

import ART
import SFSymbols

import SwiftUI

private typealias ThisView = SettingsView

struct SettingsView: ModelView {
  enum Event: Hashable {
    case tapOnCloseButton
    case tapOnSaveButton(openAiApiSettings: OpenAiApiSettings)
  }

  struct Model: Equatable {
    var openAiApiSettings: OpenAiApiSettings
  }

  let context: Context<Coeffects>

  init(context: Context<Coeffects>) {
    self.context = context
    self.openAiApiKey = context.model.openAiApiSettings.apiKey
    self.openAiChatModel = context.model.openAiApiSettings.chatModel
    self.openAiImageGenerationModel = context.model.openAiApiSettings.imageGenerationModel
  }

  @State
  private var openAiApiKey: String

  @State
  private var openAiChatModel: String

  @State
  private var openAiImageGenerationModel: String

  var body: some View {
    ZStack {
      Color.popoverViewBackgroundColor

      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .center, spacing: 0) {
          ActionButton(
            .sf_xmark,
            .tapOnCloseButton,
            scaleFactor: 0.8
          )

          Spacer()

          Text("Settings")
            .font(.companionTitleFont)
            .foregroundColor(.historyViewForeroundColor)

          Spacer()

          ActionButton(
            .sf_checkmark,
            .tapOnSaveButton(
              openAiApiSettings: .init(
                apiKey: self.openAiApiKey,
                chatModel: self.openAiChatModel,
                imageGenerationModel: self.openAiImageGenerationModel
              )
            ),
            scaleFactor: 0.8
          )
        }
        .padding(.bottom, 20)

        TextSetting(
          "OpenAI API key",
          self.$openAiApiKey,
          placeholderText: "Insert key here"
        )

        TextSetting(
          "OpenAI chat model",
          self.$openAiChatModel,
          placeholderText: OpenAiApiSettings.defaultChatModel,
          shouldAutocorrect: false,
          textInputAutocapitalization: .never
        )

        TextSetting(
          "OpenAI image generation model",
          self.$openAiImageGenerationModel,
          placeholderText: OpenAiApiSettings.defaultImageGenerationModel,
          shouldAutocorrect: false,
          textInputAutocapitalization: .never
        )

        Spacer()
      }
      .padding(.init(top: 20, leading: 10, bottom: 20, trailing: 10))
    }
  }
}

extension SettingsView {
  private func TextSetting(
    _ text: String,
    _ binding: Binding<String>,
    placeholderText: String,
    shouldAutocorrect: Bool = true,
    textInputAutocapitalization: TextInputAutocapitalization = .sentences
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(text)
        .font(.companionBodyFont)
        .foregroundColor(Color.defaultForegroundColor)
        .padding([.leading, .bottom], 10)

      Companion.TextField(
        placeholderText: placeholderText,
        binding: binding,
        shouldAutocorrect: shouldAutocorrect,
        font: .companionApiFont,
        textInputAutocapitalization: textInputAutocapitalization
      )
    }
    .padding(.bottom, 20)
  }
}
