export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(statusCode: number, code: string, message: string, details?: unknown) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;

    // Fix prototype chain when targeting ES5 (safe here, harmless otherwise).
    Object.setPrototypeOf(this, ApiError.prototype);
  }

  static badRequest(code: string, message: string, details?: unknown): ApiError {
    return new ApiError(400, code, message, details);
  }

  static unauthorized(code: string, message: string, details?: unknown): ApiError {
    return new ApiError(401, code, message, details);
  }

  static forbidden(code: string, message: string, details?: unknown): ApiError {
    return new ApiError(403, code, message, details);
  }

  static notFound(code: string, message: string, details?: unknown): ApiError {
    return new ApiError(404, code, message, details);
  }

  static tooManyRequests(code: string, message: string, details?: unknown): ApiError {
    return new ApiError(429, code, message, details);
  }
}

