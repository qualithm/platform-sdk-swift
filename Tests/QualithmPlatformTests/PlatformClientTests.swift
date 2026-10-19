import Foundation
import QualithmPlatform
import Testing

@Suite(.serialized)
struct PlatformClientTests {
  let deviceID = UUID(uuidString: "0B9F8A1E-8C1D-4B6F-9A51-2F6C1E3D4A5B") ?? UUID()

  func json(_ value: String) -> Data { Data(value.utf8) }

  func client(
    token: String? = "qmt_test", baseURL: String? = nil, environment: [String: String] = [:]
  )
    throws -> PlatformClient
  {
    stubSession = StubSession()
    return try PlatformClient(
      token: token, baseURL: baseURL, environment: environment, requestBuilderFactory: StubFactory()
    )
  }

  @Test func sendsTheTokenToTheProductionAPIByDefault() async throws {
    let platform = try client()
    stubSession.respond(StubAnswer(body: json(#"{"data":{"current":1,"items":[],"last":1}}"#)))

    let page = try await platform.call {
      try await DevicesAPI.listDevices(page: 2, limit: 10, apiConfiguration: $0)
    }

    #expect(page.data.items.isEmpty)
    let request = try #require(stubSession.requests.first)
    #expect(
      request.url?.absoluteString == "https://api.qualithm.com/devices?limit=10&page=2"
        || request.url?.absoluteString == "https://api.qualithm.com/devices?page=2&limit=10")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer qmt_test")
  }

  @Test func readsTheTokenAndBaseURLFromTheEnvironment() async throws {
    let platform = try client(
      token: nil,
      environment: [
        "QUALITHM_API_TOKEN": "qmt_env", "QUALITHM_API_URL": "https://api.dev.qualithm.com/",
      ])
    stubSession.respond(StubAnswer(body: json(#"{"status":"ok"}"#)))

    _ = try await platform.call { try await HealthAPI.getHealthz(apiConfiguration: $0) }

    let request = try #require(stubSession.requests.first)
    #expect(request.url?.absoluteString == "https://api.dev.qualithm.com/healthz")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer qmt_env")
  }

  @Test func prefersArgumentsOverTheEnvironment() async throws {
    let platform = try client(
      token: "qmt_arg", baseURL: "http://localhost:3000",
      environment: ["QUALITHM_API_TOKEN": "qmt_env", "QUALITHM_API_URL": "https://example.com"])
    stubSession.respond(StubAnswer(body: json(#"{"status":"ok"}"#)))

    _ = try await platform.call { try await HealthAPI.getHealthz(apiConfiguration: $0) }

    let request = try #require(stubSession.requests.first)
    #expect(request.url?.absoluteString == "http://localhost:3000/healthz")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer qmt_arg")
  }

  @Test func refusesToStartWithoutAToken() {
    #expect(throws: PlatformError.missingToken) {
      try PlatformClient(environment: ["QUALITHM_API_TOKEN": ""])
    }
    #expect(PlatformError.missingToken.code == .unauthorized)
    #expect(PlatformError.missingToken.status == 0)
    #expect(
      PlatformError.missingToken.message
        == "api token missing: pass token or set QUALITHM_API_TOKEN")
  }

  func failure(_ answer: StubAnswer) async throws -> PlatformError {
    let platform = try client()
    stubSession.respond(answer)
    do {
      _ = try await platform.call {
        try await DevicesAPI.getDevice(deviceId: deviceID, apiConfiguration: $0)
      }
    } catch {
      return error
    }
    Issue.record("expected the call to fail")
    return .transport(message: "")
  }

  @Test func carriesTheEnvelopesCodeMessageAndStatus() async throws {
    let error = try await failure(
      StubAnswer(status: 404, body: json(#"{"message":"device not found","code":"not_found"}"#)))
    #expect(error == .api(status: 404, code: .notFound, message: "device not found"))
    #expect(error.code == .notFound)
    #expect(error.status == 404)
    #expect(error.message == "device not found")
  }

  @Test func decodesAnUnknownCodeToTheFallback() async throws {
    let error = try await failure(
      StubAnswer(
        status: 422,
        body: json(#"{"message":"device limit reached","code":"device_limit_reached"}"#)))
    #expect(error.code == .unknownDefaultOpenApi)
    #expect(error.message == "device limit reached")
  }

  @Test func namesTheStatusWhenTheBodyIsNotAnEnvelope() async throws {
    let error = try await failure(StubAnswer(status: 502, body: json("<html>bad gateway</html>")))
    #expect(
      error
        == .api(
          status: 502, code: .unknownDefaultOpenApi, message: "request failed with status 502"))
  }

  @Test func wrapsARequestThatNeverGotAResponse() async throws {
    let error = try await failure(StubAnswer(error: URLError(.notConnectedToInternet)))
    guard case .transport(let message) = error else {
      Issue.record("expected a transport error, got \(error)")
      return
    }
    #expect(message.hasPrefix("request failed: "))
    #expect(error.status == 0)
    #expect(error.code == .unknownDefaultOpenApi)
  }
}
