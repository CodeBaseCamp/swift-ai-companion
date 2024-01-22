// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation
import SwiftUI

actor SideEffectPerformer: TaskBasedSideEffectPerformerProtocol {
  typealias Result<Error: ErrorProtocol> =
    CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>
  typealias SideEffectClosure = (SideEffect, Coeffects) async -> Result<SideEffectError>

  /// Internally used side effect performer.
  private let sideEffectPerformer: ART.TaskBasedSideEffectPerformer<
    SideEffect,
    SideEffectError,
    Coeffects
  >

  init(sideEffectClosure: @escaping SideEffectClosure) {
    self.sideEffectPerformer = .init(sideEffectClosure: sideEffectClosure)
  }

  func perform(
    _ sideEffect: Companion.CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Result<SideEffectError> {
    await self.sideEffectPerformer.perform(sideEffect, using: coeffects)
  }

  func task(
    performing sideEffect: Companion.CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Task<Result<SideEffectError>, Swift.Error> {
    return Task { [unowned self] in
      return await self.perform(sideEffect, using: coeffects)
    }
  }
}

extension SideEffectPerformer {
  typealias URLRequestHandlingClosure = (URLRequest) async throws -> (Data, URLResponse)

  struct OpenAiRequest<T: Decodable> {
    var apiKey: String
    var prompt: String
    var apiURL: URL
    var responseType: T.Type
    var responseExtractionError: URLSessionDataTaskError
    var jsonObject: [String: Any]
  }

  static func newDefaultInstance(
    handleUrlRequest: @escaping URLRequestHandlingClosure =
      { try await URLSession.shared.data(for: $0) },
    imageDownloadClosure: @escaping (URL) async -> (Data, URLResponse)? =
      { try? await URLSession.shared.data(from: $0) },
    handle: @escaping (Request) -> Void
  ) -> SideEffectPerformer {
    return .init() { sideEffect, coeffects in
      switch sideEffect {
      case let .textGeneration(prompt, api, entryID):
        switch api {
        case let .openAi(apiSettings):
          let request = OpenAiRequest(
            apiKey: apiSettings.apiKey,
            prompt: prompt,
            apiURL: .openAiChatURL,
            responseType: OpenAiChatResponse.self,
            responseExtractionError: .chatResponseExtraction,
            jsonObject: [
              "model": apiSettings.chatModel,
              "messages": [
                [
                  "role": "user",
                  "content": prompt
                ]
              ],
              "max_tokens": 500,
            ]
          )

          switch await Self.handleOpenAiRequest(request, handleUrlRequest: handleUrlRequest) {
          case let .failure(error):
            return .failure(.simpleError(.customError(.urlSessionDataTask(error))))
          case let .success(response):
            guard !response.choices.isEmpty else {
              return .failure(.simpleError(.customError(.urlSessionDataTask(.invalidChatResponse))))
            }

            handle(.finalizingOfEntry(withID: entryID, .text(response.choices[0].message.content)))
            return .success
          }
        }
      case let .imageGeneration(prompt, dimension, api, entryID):
        switch api {
        case let .openAi(apiSettings):
          let request = OpenAiRequest(
            apiKey: apiSettings.apiKey,
            prompt: prompt,
            apiURL: .openAiImageGenerationURL,
            responseType: OpenAiImageResponse.self,
            responseExtractionError: .imageResponseExtraction,
            jsonObject: [
              "prompt": prompt,
              "model": apiSettings.imageGenerationModel,
              "size": "\(dimension)x\(dimension)",
            ]
          )
          
          let response = await Self.handleOpenAiRequest(
            request,
            handleUrlRequest: handleUrlRequest
          )

          switch response {
          case let .failure(error):
            return .failure(.simpleError(.customError(.urlSessionDataTask(error))))
          case let .success(response):
            let optionalImages = await withTaskGroup(of: UIImage?.self) { taskGroup in
              let urls = response.data.compactMap { URL(string: $0.url) }
              urls.forEach { url in
                taskGroup.addTask {
                  guard let (data, _) = await imageDownloadClosure(url) else {
                    return nil
                  }
                  return UIImage(data: data)
                }
              }

              var images = [UIImage?]()
              for await result in taskGroup {
                images.append(result)
              }
              return images
            }
            let images = optionalImages.compactMap { $0 }

            handle(
              .finalizingOfEntry(withID: entryID, images.isEmpty ? .failure : .images(images))
            )

            return .success
          }
        }
      }
    }
  }

  private static func handleOpenAiRequest<T: Decodable>(
    _ request: OpenAiRequest<T>,
    handleUrlRequest: @escaping URLRequestHandlingClosure
  ) async -> Swift.Result<T, URLSessionDataTaskError> {
    let result = await Self.handle(
      .postRequest(
        .openAiModerationsURL,
        apiKey: request.apiKey,
        jsonObject: ["input": request.prompt]
      ),
      handleUrlRequest: handleUrlRequest
    )

    switch result {
    case let .failure(error):
      return .failure(error)
    case let .success(data):
      guard
        let response = try? JSONDecoder().decode(OpenAiModerationResponse.self, from: data),
        !response.results.isEmpty
      else {
        return .failure(.moderationResponseExtraction)
      }

      guard !response.results[0].flagged else {
        return .failure(.flaggedPrompt)
      }

      let result = await Self.handle(
        .postRequest(request.apiURL, apiKey: request.apiKey, jsonObject: request.jsonObject),
        handleUrlRequest: handleUrlRequest
      )

      switch result {
      case let .failure(error):
        return .failure(error)
      case let .success(data):
        guard let response = try? JSONDecoder().decode(request.responseType, from: data)
        else {
          return .failure(request.responseExtractionError)
        }

        return .success(response)
      }
    }
  }

  private static func handle(
    _ request: URLRequest,
    handleUrlRequest: @escaping URLRequestHandlingClosure
  ) async -> Swift.Result<Data, URLSessionDataTaskError> {
    do {
      let (data, response) = try await handleUrlRequest(request)

      guard
        let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        return .failure(.response((response as? HTTPURLResponse)?.statusCode ?? -1))
      }

      return .success(data)
    } catch let error {
      return .failure(.general(error.localizedDescription))
    }
  }
}

public enum URLSessionDataTaskError: ErrorProtocol {
  case general(String)
  case response(Int)
  case moderationResponseExtraction
  case flaggedPrompt
  case chatResponseExtraction
  case imageResponseExtraction
  case invalidChatResponse
  case invalidImageResponse
}

extension URLSessionDataTaskError: HumanReadable {
  public var humanReadableDescription: String {
    switch self {
    case let .general(errorDescription):
      return "general error: \(errorDescription)"
    case let .response(errorCode):
      return "response error: \(errorCode)"
    case .moderationResponseExtraction:
      return "moderation response extraction error"
    case .flaggedPrompt:
      return "flagged prompt error"
    case .chatResponseExtraction:
      return "chat response extraction error"
    case .invalidChatResponse:
      return "invalid chat response error"
    case .imageResponseExtraction:
      return "image response extraction error"
    case .invalidImageResponse:
      return "invalid image response error"
    }
  }
}

extension CompletionIndication
where Error == CompositeError<SideEffectExecutionError<Companion.Error>>
{
  static func failure(_ error: URLSessionDataTaskError) -> Self {
    return .failure(.simpleError(.customError(.sideEffect(.urlSessionDataTask(error)))))
  }
}

extension SideEffectPerformer {
  static func productionInstance(
    _ handle: @escaping (Request) -> Void
  ) -> SideEffectPerformer {
    return .newDefaultInstance(handle: handle)
  }

  static func fakeInstance(
    _ handle: @escaping (Request) -> Void,
    shouldSucceed: Bool = true
  ) -> SideEffectPerformer {
    let statusCode = shouldSucceed ? 200 : 0

    return .newDefaultInstance(
      handleUrlRequest: { request in
        let data: Data
        switch request.url {
        case URL.openAiModerationsURL:
          data = .fakeOpenAiModerationResponseData
        case URL.openAiChatURL:
          data = .fakeOpenAiChatResponseData
        case URL.openAiImageGenerationURL:
          data = .fakeOpenAiImageResponseData
        default:
          fatalError("Unhandled URL: \(request.url?.absoluteString ?? "")")
        }

        return (
          data,
          requiredLet(
            HTTPURLResponse(
              url: requiredLet(request.url, "Should exist for request \(request)"),
              statusCode: statusCode,
              httpVersion: nil,
              headerFields: nil
            ),
            "Must be creatable"
          )
        )
      },
      handle: handle
    )
  }
}

private extension Data {
  static let fakeOpenAiModerationResponseData = try! JSONEncoder().encode(
    OpenAiModerationResponse(
      results: [
        .init(flagged: false)
      ]
    )
  )

  static let fakeOpenAiChatResponseData = try! JSONEncoder().encode(
    OpenAiChatResponse(
      choices: [
        .init(message: .init(role: "system", content: "I am an ignorant AI companion."))
      ]
    )
  )

  static let fakeOpenAiImageResponseData = try! JSONEncoder().encode(
    OpenAiImageResponse(
      created: 0,
      data: [.init(url: "https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=1024")]
    )
  )
}
