export type ApiSuccessResponse<T> = {
  success: true;
  data: T;
};

export type ApiErrorResponse = {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
};

export function toSuccess<T>(data: T): ApiSuccessResponse<T> {
  return { success: true, data };
}

export function toError(code: string, message: string, details?: unknown): ApiErrorResponse {
  return { success: false, error: { code, message, details } };
}

