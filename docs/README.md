# Animate AV Public Docs

This folder contains public, frontend-safe documentation for the Animate AV iOS
app repository.

Keep this repo limited to information that is safe to publish with the client
code. Product strategy, pricing, App Store review notes, promo codes, provider
choices, retention operations, model policy, revenue assumptions, and release
handoff values belong in the private AVALSYS suite.

## Included Here

- Shared Apple app pattern: Animate AV follows the public
  [Apps AV Apple Product App Patterns](https://github.com/miguelavalos/apps-av/blob/main/docs/apple-product-app-patterns.md)
  guide for Account AV, app shell, settings, config hygiene, and shared package
  usage.
- [install-ios.md](install-ios.md): local iOS setup and compile checks.
- [client-architecture-guardrails.md](client-architecture-guardrails.md):
  public-safe iOS ownership rules for backend-owned workflows, backend-issued
  realtime sessions, and subscription-only Convex state.
- [production-config.md](production-config.md): public runtime-config hygiene,
  with no production values.
- [release-checklist.md](release-checklist.md): public repo readiness checks.
- [release-evidence-template.md](release-evidence-template.md): non-secret
  technical evidence template.
- [canonical-asset-handoff.md](canonical-asset-handoff.md): public-safe asset
  approval record before adding final client artwork.
- [look-preview-assets.md](look-preview-assets.md): naming and generation
  convention for look selector preview assets.
- [look-preview-handoff-prompt.md](look-preview-handoff-prompt.md): continuation
  prompt for finishing GPT Image 2 look previews on another machine.
- [app-store-screenshots.md](app-store-screenshots.md): public screenshot safety
  rules for non-secret captures.
- [app-privacy-inventory.md](app-privacy-inventory.md), [app-review-notes.md](app-review-notes.md),
  and [app-store-metadata.md](app-store-metadata.md): public placeholders that
  intentionally keep private release material out of this repo.

## Current Public Product Shape

V1 is a signed-in one-photo animation workflow:

```text
Photo / Frame -> Look -> Movement -> optional Message / Voice -> Check cost -> Create video -> local download -> Gallery
```

Photo / Frame is the normal source-photo step: choose one photo, use the full
photo, adjust the frame, change photo, or discard the draft. If the user adjusts
the frame, that adjusted image becomes the source photo for that workflow. The
public client does not need to keep a separate pre-adjustment copy for workflow
metadata.

Movement is a separate setup choice from Message / Voice. It controls what
visually moves in the animation. Message and voice are optional; a visual-only
video with no message and no narration is a valid v1 path.

Local no-spend QA may use fixture or mock final-render routes to reach the
confirmation and queued/completed states. Do not use public docs to authorize a
paid provider smoke; that approval belongs in the private runbook.

The public client may also expose image generation from a source photo as a
separate Images workflow. Generated images are visible user assets and may be
downloaded, shared, or used as video input when the signed backend supports that
state.

The public client should not describe a generated video preview step,
model/provider choices, generated audio options, captions, subtitles, text
overlays, or permanent cloud media storage as v1 features. Video output always
has backend-generated audio in v1; the user does not upload or edit audio.

Backend-backed in-progress video/image state and finished Gallery metadata may
recover after sign-in. Local media files remain device-local availability: a
Gallery item can exist while its video or image file is missing on the current
device, and redownload is offered only when the backend reports an available
artifact.

Current polish note: the implementation still contains visible `Gallery` and
`In Progress` labels from the reusable Apps AV foundation. Those labels are
under product review for Animate AV. Do not rename backend/local-first media
behavior blindly; audit the user-facing terminology first.

Create Video look review note: the current target is 8 look families with 8
looks each, one unique preview asset per look, and deterministic default voice
mapping by family position. The guided voice picker is accepted for now; review
the look picker before changing voices.

## Branding And First Run

Animate AV follows the shared Apps AV first-run sequence:

```text
native launch logo + icon -> product splash with Avi -> onboarding
```

The native launch frame uses the approved Animate AV logo lockup with the
Animate icon/mark. The splash uses product-specific generated artwork where Avi
acts as the assistant for turning a source photo into an animated result.
Onboarding may reuse the same concept, but should not duplicate Avi in the
background when Avi is already shown near the primary call-to-action.

The public client must treat realtime state as read-only synced product state.
User actions go through authenticated backend commands; owner-scoped realtime
subscriptions start only after the backend issues a realtime session for the
signed-in account.

## Private-Only Topics

These topics must not be documented in this public repo:

- App Store Connect review notes or reviewer credentials;
- promo codes, campaign setup, or App Review access strategy;
- pricing, credit grants, margins, product policy, or RevenueCat setup;
- provider/model selection, costs, failure rates, or routing;
- backend storage, retention operations, internal URLs, or admin controls;
- legal/privacy drafts that describe internal processing beyond public policy
  links;
- unreleased product strategy or business positioning.

The placeholder files for App Store metadata, App Review notes, and App Privacy
inventory exist only to prevent accidental public planning. Their working
versions are maintained privately.

## Public Data Safety

Do not include secrets, signing material, production config, private URLs,
purchase receipts, account identifiers, selected user media, generated videos,
provider request IDs, internal logs, or demo account details in public issues,
pull requests, screenshots, or release evidence.

## Signed Workflow Validation

This public repo is not the source of truth for signed preview/dev validation.
When a task touches Account AV identity, credits, uploads, Convex state, final
render, artifacts, purchases, or deletion, follow the private native validation
runbook in `private/avalsys-suite`. Public docs may describe client behavior,
but not private Cloudflare/Convex/provider procedures.
