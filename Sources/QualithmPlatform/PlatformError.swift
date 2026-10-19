import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Every failure a platform call raises. Branch on ``code``, never on ``message``.
public enum PlatformError: Error, Sendable, Equatable {
  /// The API answered with an error envelope: its HTTP status, stable code and message.
  case api(status: Int, code: ApiErrorCode, message: String)
  /// The request never got a usable response.
  case transport(message: String)
  /// No API token was passed or set in `QUALITHM_API_TOKEN`.
  case missingToken

  /// The envelope's stable code. A code this version doesn't know yet, or a failure with no
  /// response, reads as `.unknownDefaultOpenApi`; a missing token reads as `.unauthorized`.
  public var code: ApiErrorCode {
    switch self {
    case .api(_, let code, _): code
    case .transport: .unknownDefaultOpenApi
    case .missingToken: .unauthorized
    }
  }

  /// The HTTP status, or `0` when no response arrived.
  public var status: Int {
    switch self {
    case .api(let status, _, _): status
    case .transport, .missingToken: 0
    }
  }

  /// What failed, lowercase.
  public var message: String {
    switch self {
    case .api(_, _, let message): message
    case .transport(let message): message
    case .missingToken: "api token missing: pass token or set QUALITHM_API_TOKEN"
    }
  }

  /// Builds the error for a generated call's failure, reading the `{ message, code }` envelope
  /// from an error response.
  static func from(_ error: ErrorResponse) -> PlatformError {
    guard case .error(_, let data, let response, let underlying) = error else {
      return .transport(message: "request failed")
    }
    guard let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) else {
      return .transport(message: "request failed: \(String(describing: underlying).lowercased())")
    }
    let envelope = data.flatMap { try? JSONDecoder().decode(Envelope.self, from: $0) }
    let message =
      envelope?.message.flatMap { $0.isEmpty ? nil : $0 }
      ?? "request failed with status \(http.statusCode)"
    return .api(
      status: http.statusCode, code: envelope?.code ?? .unknownDefaultOpenApi, message: message)
  }

  private struct Envelope: Decodable {
    let message: String?
    let code: ApiErrorCode?

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      message = try? container.decode(String.self, forKey: .message)
      code = (try? container.decode(String.self, forKey: .code)).map {
        ApiErrorCode(rawValue: $0) ?? .unknownDefaultOpenApi
      }
    }

    private enum CodingKeys: String, CodingKey {
      case message, code
    }
  }
}
