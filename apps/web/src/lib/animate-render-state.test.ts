import { describe, expect, test } from "bun:test";
import { animateCreateInputLimits, canSubmitConfirm, createFinalConfirmIdempotencyKey, createRenderPlanInputSignature, creditAvailabilityMessage, finalRenderQueuedMessage, isRenderPlanCurrent, renderPlanBlockerSummary, spendableCredits } from "./animate-render-state";

describe("Animate render state", () => {
  test("keeps Create input limits aligned to the Animate workflow contract", () => {
    expect(animateCreateInputLimits.actionHintMaxLength).toBe(80);
    expect(animateCreateInputLimits.messageMaxLength).toBe(150);
  });

  test("builds a stable confirm idempotency key from the render plan input", () => {
    const input = { videoId: "video-1", planId: "plan-1", inputSignature: JSON.stringify({ look: "cartoon" }) };

    expect(createFinalConfirmIdempotencyKey(input)).toBe(createFinalConfirmIdempotencyKey(input));
    expect(createFinalConfirmIdempotencyKey({ ...input, inputSignature: JSON.stringify({ look: "anime" }) })).not.toBe(createFinalConfirmIdempotencyKey(input));
  });

  test("blocks duplicate local confirm submissions while the same key is in flight", () => {
    expect(canSubmitConfirm("key-1", "key-1")).toBe(false);
    expect(canSubmitConfirm("key-1", "key-2")).toBe(true);
    expect(canSubmitConfirm(null, "key-1")).toBe(true);
  });

  test("requires the reviewed render plan to match the current setup before confirmation", () => {
    expect(isRenderPlanCurrent("signature-1", "signature-1")).toBe(true);
    expect(isRenderPlanCurrent("signature-1", "signature-2")).toBe(false);
    expect(isRenderPlanCurrent(null, "signature-1")).toBe(false);
  });

  test("normalizes render plan signatures while preserving material setup changes", () => {
    const base = {
      videoId: " video-1 ",
      sourceImageUploadId: " upload-1 ",
      sourceLocalIdentifier: " source-1 ",
      frameMode: "full",
      look: " cartoon ",
      actionHint: "  gentle wave  ",
      messageText: "  hello  ",
      startsWithSourcePhoto: true
    };
    const signature = createRenderPlanInputSignature(base);

    expect(createRenderPlanInputSignature({
      ...base,
      videoId: "video-1",
      sourceImageUploadId: "upload-1",
      sourceLocalIdentifier: "source-1",
      look: "cartoon",
      actionHint: "gentle wave",
      messageText: "hello"
    })).toBe(signature);
    expect(createRenderPlanInputSignature({ ...base, look: "anime" })).not.toBe(signature);
    expect(createRenderPlanInputSignature({ ...base, sourceImageUploadId: "upload-2" })).not.toBe(signature);
    expect(createRenderPlanInputSignature({ ...base, frameMode: "portrait" })).not.toBe(signature);
    expect(createRenderPlanInputSignature({ ...base, messageText: "different" })).not.toBe(signature);
    expect(createRenderPlanInputSignature({ ...base, startsWithSourcePhoto: false })).not.toBe(signature);
  });

  test("does not treat a loading credit balance as zero", () => {
    expect(spendableCredits(undefined, false)).toBeNull();
    expect(spendableCredits(undefined, true)).toBe(0);
    expect(spendableCredits({ walletSummary: { credits: { available: 3 } } }, true)).toBe(3);
    expect(spendableCredits({ spendableCredits: 4, walletSummary: { credits: { available: 3 } } }, true)).toBe(4);
  });

  test("explains credit availability without using loading as zero", () => {
    expect(creditAvailabilityMessage(null, 2)).toContain("loading");
    expect(creditAvailabilityMessage(1, 2)).toContain("this plan costs 2");
    expect(creditAvailabilityMessage(3, 2)).toContain("available for a 2-credit plan");
  });

  test("summarizes plan blockers without leaking raw backend copy", () => {
    const copy = { none: "None", planBlockers: "Plan returned blockers." };

    expect(renderPlanBlockerSummary([], copy)).toBe("None");
    expect(renderPlanBlockerSummary(["insufficient_credits", "backend english detail"], copy)).toBe("Plan returned blockers. (2)");
  });

  test("uses localized final queued copy instead of backend user messages", () => {
    expect(finalRenderQueuedMessage({ finalQueued: "Cola localitzada" })).toBe("Cola localitzada");
  });
});
