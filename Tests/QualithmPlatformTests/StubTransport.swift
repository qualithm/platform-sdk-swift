import Foundation
import QualithmPlatform

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// One canned answer: a status and body, or a transport error.
struct StubAnswer: Sendable {
  var status = 200
  var body = Data()
  var error: URLError?
}

/// Records each request and answers it from a canned ``StubAnswer``.
final class StubSession: URLSessionProtocol, @unchecked Sendable {
  private let lock = NSLock()
  private var answer = StubAnswer()
  private var recorded: [URLRequest] = []

  func respond(_ answer: StubAnswer) {
    lock.withLock { self.answer = answer }
  }

  var requests: [URLRequest] { lock.withLock { recorded } }

  func dataTaskFromProtocol(
    with request: URLRequest,
    completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
  ) -> URLSessionDataTaskProtocol {
    let answer = lock.withLock {
      recorded.append(request)
      return self.answer
    }
    return StubTask {
      if let error = answer.error {
        completionHandler(nil, nil, error)
        return
      }
      let response = HTTPURLResponse(
        url: request.url ?? URL(fileURLWithPath: "/"), statusCode: answer.status,
        httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])
      completionHandler(answer.body, response, nil)
    }
  }
}

final class StubTask: URLSessionDataTaskProtocol {
  private let run: () -> Void
  init(_ run: @escaping () -> Void) { self.run = run }
  func resume() { run() }
  var taskIdentifier: Int { 0 }
  var progress: Progress { Progress(totalUnitCount: 0) }
  func cancel() {}
}

/// The one session every stub builder uses, set by each test.
nonisolated(unsafe) var stubSession = StubSession()

final class StubBuilder<T: Sendable>: URLSessionRequestBuilder<T>, @unchecked Sendable {
  override func createURLSession() -> URLSessionProtocol { stubSession }
}

final class StubDecodableBuilder<T: Decodable & Sendable>: URLSessionDecodableRequestBuilder<T>,
  @unchecked Sendable
{
  override func createURLSession() -> URLSessionProtocol { stubSession }
}

struct StubFactory: RequestBuilderFactory {
  func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type { StubBuilder<T>.self }
  func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type { StubDecodableBuilder<T>.self }
}
