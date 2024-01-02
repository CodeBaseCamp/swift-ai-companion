// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation
import SwiftUI

class SideEffectPerformer: SideEffectPerformerProtocol {
  typealias Error = Companion.Error

  /// Internally used side effect performer.
  private let sideEffectPerformer: ART.SideEffectPerformer<
    SideEffect,
    Error,
    Coeffects,
    BackgroundDispatchQueueID
  >

  init(
    dispatchQueues: [DispatchQueueID<BackgroundDispatchQueueID>: DispatchQueue] = .default,
    sideEffectClosure: @escaping SideEffectClosure
  ) {
    self.sideEffectPerformer = .init(
      dispatchQueues: dispatchQueues,
      sideEffectClosure: sideEffectClosure
    )
  }

  func perform(
    _ sideEffect: Companion.CompositeSideEffect,
    using coeffects: Coeffects,
    completion: @escaping CompletionClosure
  ) {
    self.sideEffectPerformer.perform(sideEffect, using: coeffects, completion: completion)
  }
}

extension SideEffectPerformer {
  typealias URLRequestHandlingClosure =
    (URLRequest, @escaping @Sendable (Data?, URLResponse?, Swift.Error?) -> Void) -> Void

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
      { URLSession.shared.dataTask(with: $0, completionHandler: $1).resume() },
    imageDownloadClosure: @escaping (URL) async -> (Data, URLResponse)? =
      { try? await URLSession.shared.data(from: $0) },
    handle: @escaping (Request) -> Void
  ) -> SideEffectPerformer {
    return .init(dispatchQueues: .default) { sideEffect, coeffects, completion in
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

          Self.handleOpenAiRequest(
            request,
            handleUrlRequest: handleUrlRequest,
            errorClosure: { completion(.failure($0)) }
          ) { response in
            guard !response.choices.isEmpty else {
              completion(.failure(.invalidChatResponse))
              return
            }

            handle(.finalizingOfEntry(withID: entryID, .text(response.choices[0].message.content)))
            completion(.success)
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
          
          Self.handleOpenAiRequest(
            request,
            handleUrlRequest: handleUrlRequest,
            errorClosure: { completion(.failure($0)) }
          ) { response in
            Task {
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
              completion(.success)
            }
          }
        }
      }
    }
  }

  private static func handleOpenAiRequest<T: Decodable>(
    _ request: OpenAiRequest<T>,
    handleUrlRequest: @escaping URLRequestHandlingClosure,
    errorClosure: @escaping (URLSessionDataTaskError) -> Void,
    completion: @escaping (T) -> Void
  ) {
    Self.handle(
      .postRequest(
        .openAiModerationsURL,
        apiKey: request.apiKey,
        jsonObject: ["input": request.prompt]
      ),
      handleUrlRequest: handleUrlRequest
    ) {
      switch $0 {
      case let .failure(error):
        errorClosure(error)
        return
      case let .success(data):
        guard
          let response = try? JSONDecoder().decode(OpenAiModerationResponse.self, from: data),
          !response.results.isEmpty
        else {
          errorClosure(.moderationResponseExtraction)
          return
        }

        guard !response.results[0].flagged else {
          errorClosure(.flaggedPrompt)
          return
        }

        Self.handle(
          .postRequest(request.apiURL, apiKey: request.apiKey, jsonObject: request.jsonObject),
          handleUrlRequest: handleUrlRequest
        ) {
          switch $0 {
          case let .failure(error):
            errorClosure(error)
            return
          case let .success(data):
            guard let response = try? JSONDecoder().decode(request.responseType, from: data)
            else {
              errorClosure(request.responseExtractionError)
              return
            }

            completion(response)
          }
        }
      }
    }
  }

  private static func handle(
    _ request: URLRequest,
    handleUrlRequest: @escaping URLRequestHandlingClosure,
    completion: @escaping (Result<Data, URLSessionDataTaskError>) -> Void
  ) {
    handleUrlRequest(request) { data, response, error in
      if let error = error {
        completion(.failure(.general(error.localizedDescription)))
        return
      }

      guard
        let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        completion(
          .failure(.response((response as? HTTPURLResponse)?.statusCode ?? -1))
        )
        return
      }

      guard let data = data else {
        completion(.failure(.dataExtraction))
        return
      }
      completion(.success(data))
    }
  }
}

public enum URLSessionDataTaskError: ErrorProtocol {
  case general(String)
  case response(Int)
  case dataExtraction
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
    case .dataExtraction:
      return "data extraction error"
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

private extension Dictionary where Key == DispatchQueueID<BackgroundDispatchQueueID>,
                                   Value == DispatchQueue {
  static let `default`: Self = [
    .mainThread: .main,
    .backgroundThread(.defaultInstance): .global()
  ]
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
      handleUrlRequest: { request, completionClosure in
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

        completionClosure(
          data,
          HTTPURLResponse(
            url: requiredLet(request.url, "Should exist for request \(request)"),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
          ),
          nil
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
