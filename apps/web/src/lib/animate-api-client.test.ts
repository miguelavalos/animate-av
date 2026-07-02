import { describe, expect, test } from "vite-plus/test";
import { AnimateApiError, buildArtifactDownloadPayload, buildConfirmFinalRenderPayload, buildPrepareUploadPayload, buildRenameVideoPayload, buildRenderPlanPayload, requireAllowedHttpMethod, requireHttpUrl } from "./animate-api-client";

const baseInput = {
  videoId: "video-1",
  look: "cartoon",
  actionHint: "  gentle wave  ",
  selectedSourceLocalIdentifiers: ["source-1", "", "source-2"],
  sourceImageUploadId: "upload-1",
  hasMessage: true,
  messageText: "  hello exactly  ",
  removeWatermark: false,
  startsWithSourcePhoto: true
};

describe("Animate API render payload", () => {
  test("uses one normalized payload shape for render plan and final confirmation", () => {
    expect(buildRenderPlanPayload({ ...baseInput, videoId: " video-1 ", look: " cartoon ", sourceImageUploadId: " upload-1 " })).toEqual({
      videoId: "video-1",
      look: "cartoon",
      actionHint: "gentle wave",
      selectedSourceLocalIdentifiers: ["source-1", "source-2"],
      sourceImageUploadId: "upload-1",
      hasMessage: true,
      messageText: "hello exactly",
      removeWatermark: false,
      startsWithSourcePhoto: true
    });
  });

  test("does not send stale spoken text when message is disabled", () => {
    expect(buildRenderPlanPayload({ ...baseInput, hasMessage: false, messageText: "should not leak" }).messageText).toBeNull();
  });

  test("adds no-spend execution controls only when explicitly enabled", () => {
    expect(buildRenderPlanPayload(baseInput)).not.toHaveProperty("mockNoSpend");
    expect(buildRenderPlanPayload(baseInput, { mockNoSpendFinalRender: true })).toMatchObject({
      mockNoSpend: true,
      mockExecutionPreset: "all_mock"
    });
  });

  test("builds final confirmation payload with the same normalized render inputs plus required idempotency", () => {
    expect(buildConfirmFinalRenderPayload({
      ...baseInput,
      planId: " plan-1 ",
      idempotencyKey: " key-1 "
    })).toEqual({
      ...buildRenderPlanPayload(baseInput),
      planId: "plan-1",
      idempotencyKey: "key-1"
    });
  });

  test("blocks final confirmation before network when plan or idempotency is missing", () => {
    expect(() => buildConfirmFinalRenderPayload({ ...baseInput, planId: " ", idempotencyKey: "key-1" })).toThrow(AnimateApiError);
    expect(() => buildConfirmFinalRenderPayload({ ...baseInput, planId: "plan-1", idempotencyKey: " " })).toThrow(AnimateApiError);
  });

  test("blocks render plan payloads without uploaded source state", () => {
    expect(() => buildRenderPlanPayload({ ...baseInput, sourceImageUploadId: " " })).toThrow(AnimateApiError);
    expect(() => buildRenderPlanPayload({ ...baseInput, selectedSourceLocalIdentifiers: [" ", ""] })).toThrow(AnimateApiError);
  });
});

describe("Animate API workspace payloads", () => {
  test("normalizes prepare upload payloads before network", () => {
    expect(buildPrepareUploadPayload({
      videoId: " video-1 ",
      sourceLocalIdentifier: " source-1 ",
      originalFilename: " portrait.png ",
      contentType: " image/png ",
      byteSize: 1234,
      sha256: " checksum-1 ",
      width: 1080,
      height: 1920
    })).toEqual({
      appId: "animateav",
      videoId: "video-1",
      mediaKind: "photo",
      sourceLocalIdentifier: "source-1",
      originalFilename: "portrait.png",
      contentType: "image/png",
      byteSize: 1234,
      sha256: "checksum-1",
      width: 1080,
      height: 1920
    });
  });

  test("blocks impossible prepare upload payloads before network", () => {
    const uploadInput = {
      videoId: "video-1",
      sourceLocalIdentifier: "source-1",
      originalFilename: "portrait.png",
      contentType: "image/png",
      byteSize: 1234,
      sha256: "checksum-1",
      width: 1080,
      height: 1920
    };
    expect(() => buildPrepareUploadPayload({ ...uploadInput, videoId: " " })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, sourceLocalIdentifier: " " })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, originalFilename: " " })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, contentType: " " })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, byteSize: 0 })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, sha256: " " })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, width: -1 })).toThrow(AnimateApiError);
    expect(() => buildPrepareUploadPayload({ ...uploadInput, height: Number.NaN })).toThrow(AnimateApiError);
  });

  test("normalizes rename payloads before network", () => {
    expect(buildRenameVideoPayload(" video-1 ", " New title ")).toEqual({ title: "New title" });
  });

  test("blocks workspace mutations with missing identifiers before network", () => {
    expect(() => buildRenameVideoPayload(" ", "Title")).toThrow(AnimateApiError);
    expect(() => buildRenameVideoPayload("video-1", " ")).toThrow(AnimateApiError);
  });

  test("normalizes artifact download payloads before network", () => {
    expect(buildArtifactDownloadPayload(" artifact-1 ")).toEqual({ artifactId: "artifact-1" });
    expect(() => buildArtifactDownloadPayload(" ")).toThrow(AnimateApiError);
  });

  test("blocks malformed signed media URLs before network", () => {
    expect(requireHttpUrl(" https://storage.example/upload?token=1 ", "bad_url", "Bad URL")).toBe("https://storage.example/upload?token=1");
    expect(() => requireHttpUrl("/relative/upload", "bad_url", "Bad URL")).toThrow(AnimateApiError);
    expect(() => requireHttpUrl("ftp://storage.example/upload", "bad_url", "Bad URL")).toThrow(AnimateApiError);
    expect(() => requireHttpUrl(" ", "bad_url", "Bad URL")).toThrow(AnimateApiError);
  });

  test("allows only expected signed media methods before network", () => {
    expect(requireAllowedHttpMethod(" put ", ["PUT", "POST"], "bad_method", "Bad method")).toBe("PUT");
    expect(requireAllowedHttpMethod("GET", ["GET"], "bad_method", "Bad method")).toBe("GET");
    expect(() => requireAllowedHttpMethod("DELETE", ["PUT", "POST"], "bad_method", "Bad method")).toThrow(AnimateApiError);
    expect(() => requireAllowedHttpMethod(" ", ["GET"], "bad_method", "Bad method")).toThrow(AnimateApiError);
  });
});
