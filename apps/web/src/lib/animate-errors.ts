import { AnimateApiError } from "@/lib/animate-api-client";

export interface AnimateErrorCopy {
  authRequired: string;
  creditsUnavailable: string;
  downloadFailed: string;
  forbidden: string;
  notFound: string;
  planFailed: string;
  realtimeFailed: string;
  requestFailed: string;
  uploadFailed: string;
}

export function localizedAnimateErrorMessage(error: unknown, copy: AnimateErrorCopy) {
  if (!(error instanceof AnimateApiError)) {
    return error instanceof Error ? error.message : copy.requestFailed;
  }

  if (error.status === 401 || error.code === "animate_auth_required") {
    return copy.authRequired;
  }
  if (error.status === 403) {
    return copy.forbidden;
  }
  if (error.status === 404) {
    return copy.notFound;
  }
  if (error.status === 402 || error.code.includes("credit") || error.code.includes("insufficient")) {
    return copy.creditsUnavailable;
  }
  if (error.code.includes("upload")) {
    return copy.uploadFailed;
  }
  if (error.code.includes("download") || error.code.includes("artifact")) {
    return copy.downloadFailed;
  }
  if (error.code.includes("realtime")) {
    return copy.realtimeFailed;
  }
  if (error.code.includes("plan") || error.code.includes("render")) {
    return copy.planFailed;
  }
  return copy.requestFailed;
}
