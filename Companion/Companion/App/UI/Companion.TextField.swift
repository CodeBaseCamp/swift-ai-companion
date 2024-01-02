// Copyright © Rouven Strauss. All rights reserved.

import ART

import SwiftUI

extension Companion {
  struct TextField: View {
    let placeholderText: String
    let binding: Binding<String>
    let shouldAutocorrect: Bool
    let font: Font
    let textInputAutocapitalization: TextInputAutocapitalization

    init(
      placeholderText: String,
      binding: Binding<String>,
      shouldAutocorrect: Bool,
      font: Font = .body,
      textInputAutocapitalization: TextInputAutocapitalization = .sentences
    ) {
      self.placeholderText = placeholderText
      self.binding = binding
      self.shouldAutocorrect = shouldAutocorrect
      self.font = font
      self.textInputAutocapitalization = textInputAutocapitalization
    }

    var body: some View {
      SwiftUI.TextField(self.placeholderText, text: self.binding, axis: .vertical)
        .padding(.all, 10)
        .font(self.font)
        .foregroundStyle(.black)
        .textInputAutocapitalization(self.textInputAutocapitalization)
        .disableAutocorrection(!self.shouldAutocorrect)
        .multilineTextAlignment(.leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: .infinity))
        .clipped()
        .padding(.trailing, 10)
    }
  }
}
