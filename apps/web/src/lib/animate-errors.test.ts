import { describe, expect, test } from "vite-plus/test";
import { AnimateApiError } from "./animate-api-client";
import { localizedAnimateErrorMessage, type AnimateErrorCopy } from "./animate-errors";

const copy: AnimateErrorCopy = {
  authRequired: "auth localized",
  creditsUnavailable: "credits localized",
  downloadFailed: "download localized",
  forbidden: "forbidden localized",
  notFound: "not found localized",
  planFailed: "plan localized",
  realtimeFailed: "realtime localized",
  requestFailed: "request localized",
  uploadFailed: "upload localized"
};

describe("Animate localized errors", () => {
  test("maps API errors by status and code without leaking backend English messages", () => {
    expect(localizedAnimateErrorMessage(new AnimateApiError(401, "animate_auth_required", "Sign in again"), copy)).toBe(copy.authRequired);
    expect(localizedAnimateErrorMessage(new AnimateApiError(402, "insufficient_credits", "Not enough credits"), copy)).toBe(copy.creditsUnavailable);
    expect(localizedAnimateErrorMessage(new AnimateApiError(500, "animate_upload_failed", "Media upload failed"), copy)).toBe(copy.uploadFailed);
    expect(localizedAnimateErrorMessage(new AnimateApiError(500, "animate_render_plan_failed", "Plan failed"), copy)).toBe(copy.planFailed);
    expect(localizedAnimateErrorMessage(new AnimateApiError(404, "missing", "Not found"), copy)).toBe(copy.notFound);
  });

  test("preserves local browser validation errors that are already localized", () => {
    expect(localizedAnimateErrorMessage(new Error("No se ha podido leer la imagen seleccionada."), copy)).toBe("No se ha podido leer la imagen seleccionada.");
  });
});
