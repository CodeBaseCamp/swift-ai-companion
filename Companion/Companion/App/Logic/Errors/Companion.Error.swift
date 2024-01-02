// Copyright © Rouven Strauss. All rights reserved.

import ART

extension Companion {
  enum Error: ErrorProtocol {
    case textDecoding
    case imageDataDecoding

    case sideEffect(SideEffectError)
  }
}

enum SideEffectError: ErrorProtocol {
  case urlSessionDataTask(URLSessionDataTaskError)
}

extension Companion.Error: HumanReadable {
  var humanReadableDescription: String {
    switch self {
    case .textDecoding:
      return "text decoding error"
    case .imageDataDecoding:
      return "image decoding decoding error"
    case let .sideEffect(error):
      return "side effect error: \(error.humanReadableDescription)"
    }
  }
}

extension SideEffectError: HumanReadable {
  var humanReadableDescription: String {
    switch self {
    case let .urlSessionDataTask(error):
      return "URL session data task error: \(error.humanReadableDescription)"
    }
  }
}
