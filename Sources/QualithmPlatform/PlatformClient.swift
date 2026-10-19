import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The Qualithm Platform API, authenticated with one API token.
///
/// Each generated `…API` type is one resource group from the spec. Run its calls through
/// ``call(_:)``, which hands them this client's configuration and turns every failure into a
/// ``PlatformError``:
///
/// ```swift
/// let platform = try PlatformClient()
/// let page = try await platform.call { try await DevicesAPI.listDevices(apiConfiguration: $0) }
/// ```
public struct PlatformClient: Sendable {
  /// The production API; `QUALITHM_API_URL` or `baseURL` points the client elsewhere.
  public static let defaultBaseURL = "https://api.qualithm.com"

  /// The generated client configuration every call uses.
  public let configuration: QualithmPlatformAPIConfiguration

  /// Creates a client.
  ///
  /// - Parameters:
  ///   - token: An API token (`qmt_…`). Defaults to `QUALITHM_API_TOKEN`.
  ///   - baseURL: The API's base URL. Defaults to `QUALITHM_API_URL`, else the production API.
  ///   - environment: Where the defaults are read from.
  ///   - requestBuilderFactory: The transport. Defaults to `URLSession`.
  /// - Throws: ``PlatformError/missingToken`` when no token is given or set.
  public init(
    token: String? = nil,
    baseURL: String? = nil,
    environment: [String: String] = ProcessInfo.processInfo.environment,
    requestBuilderFactory: RequestBuilderFactory = URLSessionRequestBuilderFactory()
  ) throws(PlatformError) {
    let set = { (name: String) -> String? in environment[name].flatMap { $0.isEmpty ? nil : $0 } }
    guard let token = token ?? set("QUALITHM_API_TOKEN"), !token.isEmpty else {
      throw .missingToken
    }
    var base = baseURL ?? set("QUALITHM_API_URL") ?? Self.defaultBaseURL
    while base.hasSuffix("/") { base.removeLast() }
    configuration = QualithmPlatformAPIConfiguration(
      basePath: base,
      customHeaders: ["Authorization": "Bearer \(token)"],
      requestBuilderFactory: requestBuilderFactory,
      apiResponseQueue: DispatchQueue(label: "com.qualithm.platform.responses")
    )
  }

  /// Runs one generated call with this client's configuration.
  ///
  /// - Parameter operation: A generated call, given the configuration to pass as
  ///   `apiConfiguration`.
  /// - Returns: The call's decoded response.
  /// - Throws: ``PlatformError`` for every failure.
  public func call<T: Sendable>(
    _ operation: (QualithmPlatformAPIConfiguration) async throws -> T
  ) async throws(PlatformError) -> T {
    do {
      return try await operation(configuration)
    } catch let error as ErrorResponse {
      throw PlatformError.from(error)
    } catch let error as PlatformError {
      throw error
    } catch {
      throw .transport(message: "request failed: \(String(describing: error).lowercased())")
    }
  }
}
