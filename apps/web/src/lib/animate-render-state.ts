import type { AnimateCreditBalance } from "@/lib/animate-models";

export const animateCreateInputLimits = {
  actionHintMaxLength: 80,
  messageMaxLength: 150
} as const;

export interface ConfirmKeyInput {
  videoId: string;
  planId: string;
  inputSignature: string;
}

export interface RenderPlanSignatureInput {
  videoId: string;
  sourceImageUploadId: string;
  sourceLocalIdentifier: string;
  frameMode: string;
  look: string;
  actionHint: string;
  messageText: string;
  startsWithSourcePhoto: boolean;
}

export function createRenderPlanInputSignature(input: RenderPlanSignatureInput) {
  return JSON.stringify({
    videoId: input.videoId.trim(),
    sourceImageUploadId: input.sourceImageUploadId.trim(),
    sourceLocalIdentifier: input.sourceLocalIdentifier.trim(),
    frameMode: input.frameMode,
    look: input.look.trim(),
    actionHint: input.actionHint.trim(),
    messageText: input.messageText.trim(),
    startsWithSourcePhoto: input.startsWithSourcePhoto
  });
}

export function createFinalConfirmIdempotencyKey(input: ConfirmKeyInput) {
  return `web-final-confirm:${input.videoId}:${input.planId}:${hashString(input.inputSignature)}`;
}

export function spendableCredits(balance: AnimateCreditBalance | undefined, hasLoaded: boolean) {
  if (!hasLoaded) {
    return null;
  }
  return balance?.spendableCredits ?? balance?.videoCreditsAvailable ?? balance?.availableCredits ?? balance?.walletSummary?.credits?.available ?? 0;
}

export function canSubmitConfirm(currentInFlightKey: string | null, nextKey: string) {
  return currentInFlightKey !== nextKey;
}

export function isRenderPlanCurrent(planSignature: string | null, currentSignature: string) {
  return Boolean(planSignature && planSignature === currentSignature);
}

export function creditAvailabilityMessage(spendable: number | null, cost: number | null) {
  if (cost === null) {
    return spendable === null ? "Credit balance is loading." : `${spendable} credit${spendable === 1 ? "" : "s"} available.`;
  }
  if (spendable === null) {
    return `Credit balance is loading. This plan costs ${cost} credit${cost === 1 ? "" : "s"}.`;
  }
  if (spendable >= cost) {
    return `${spendable} credit${spendable === 1 ? "" : "s"} available for a ${cost}-credit plan.`;
  }
  return `${spendable} credit${spendable === 1 ? "" : "s"} available; this plan costs ${cost}.`;
}

export function renderPlanBlockerSummary(blockers: readonly string[] | undefined, copy: { none: string; planBlockers: string }) {
  const count = blockers?.length ?? 0;
  if (count === 0) {
    return copy.none;
  }
  return `${copy.planBlockers} (${count})`;
}

export function finalRenderQueuedMessage(copy: { finalQueued: string }) {
  return copy.finalQueued;
}

function hashString(value: string) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = Math.imul(31, hash) + value.charCodeAt(index) | 0;
  }
  return Math.abs(hash).toString(36);
}
