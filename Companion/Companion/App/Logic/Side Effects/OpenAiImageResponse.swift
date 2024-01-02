// Copyright © Rouven Strauss. All rights reserved.

import Foundation

struct OpenAiImageResponse: Codable {
  struct DataResponse: Codable {
    var url: String
  }

  var created: Int
  var data: [DataResponse]
}
