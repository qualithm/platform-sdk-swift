/// A stable error code the platform API can answer with. The API can add codes without a new
/// SDK version; any code this version doesn't know reads as ``unknown``.
public enum PlatformErrorCode: String, Sendable, Equatable, Hashable, CaseIterable {
  case badRequest = "bad_request"
  case unauthorized = "unauthorized"
  case forbidden = "forbidden"
  case notFound = "not_found"
  case conflict = "conflict"
  case preconditionFailed = "precondition_failed"
  case unsupportedMediaType = "unsupported_media_type"
  case unprocessableEntity = "unprocessable_entity"
  case failedDependency = "failed_dependency"
  case rateLimited = "rate_limited"
  case internalError = "internal_error"
  case backendUnavailable = "backend_unavailable"
  case lastOwner = "last_owner"
  case roleTooHigh = "role_too_high"
  case emailInUse = "email_in_use"
  case otpInvalid = "otp_invalid"
  case ownsTeam = "owns_team"
  case accountNotFound = "account_not_found"
  case alreadyMember = "already_member"
  case zoneClosed = "zone_closed"
  case zoneMismatch = "zone_mismatch"
  case planLimit = "plan_limit"
  case registeredLimit = "registered_limit"
  case nameTaken = "name_taken"
  case paidPlanRequired = "paid_plan_required"
  case scopeNotEmpty = "scope_not_empty"
  case idempotencyMismatch = "idempotency_mismatch"
  case idempotencyInFlight = "idempotency_in_flight"
  /// A code this version doesn't know yet, or a failure with no response.
  case unknown = "unknown"

  /// Reads a wire code, mapping any code this version doesn't know to ``unknown``.
  public init(code: String) {
    self = PlatformErrorCode(rawValue: code) ?? .unknown
  }
}
