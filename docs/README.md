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
Foto y encuadre -> Look -> Guide and message -> Check cost -> Create video -> local download -> Gallery
```

Foto y encuadre is the normal source-photo step: choose one photo, use the full
photo, adjust the frame, change photo, or discard the draft. If the user adjusts
the frame, that adjusted image becomes the active source photo for that
workflow. The client may retain the imported original locally while the draft is
editable so re-entering frame adjustment and restore-original work without
backend state.

Look is the main visual style choice. The Look screen must stay focused on the
8 families and 64 looks, without animation preset cards or voice controls.

Guide and message is the next guided step. The animation guide is a small
free-text hint for how the short animation should behave. The optional message
is a short written dedication/request that can be omitted. Both inputs are
basic and orientative: the client should not promise scene-accurate custom
scripts, exact control, spoken dialogue, generated narration, or complex
choreography.

Animate AV V1 does not expose a custom audio-control product. Voice lines,
narrator tone, voice cloning, uploaded audio, generated-audio settings, and
custom audio controls should stay hidden or disabled.

The client must treat the guided setup state as the source of truth for the
visible Create Video status. It must not show "Check cost" or "Ready to review
credits" until a renderable local source photo exists, a look/style is selected,
and the guided Guide and message step has been completed.
If the source photo is missing or no longer renderable, the UI resets to Foto y
encuadre and hides later steps and credit actions.

The basic guide is a compact status/helper surface for the same setup order. It
is not an additional step and must not describe unavailable audio, voice,
provider, preview-versioning, or cloud-storage features.

The final credit review mirrors the source-photo setting. When enabled, the
final video starts with the original photo before the animated video begins; the
setting has no extra credit cost and must not be described as a generated-image
preview step.

Local no-spend QA may use fixture or mock final-render routes to reach the
confirmation and queued/completed states. Do not use public docs to authorize a
paid provider smoke; that approval belongs in the private runbook.

The public client may also expose image generation from a source photo as a
separate Images workflow. Generated images are visible user assets and may be
downloaded, shared, or used as video input when the signed backend supports that
state.

The public client should not describe a generated video preview step,
model/provider choices, generated audio options, captions, subtitles, voice-over
controls, or permanent cloud media storage as v1 features. The user does not
upload, clone, or edit audio in Animate AV V1.

Backend-backed in-progress video/image state and finished Gallery metadata may
recover after sign-in. Local media files remain device-local availability: a
Gallery item can exist while its video or image file is missing on the current
device, and redownload is offered only when the backend reports an available
artifact.

Gallery video cards currently render as a two-column grid to preserve the
vertical 9:16 thumbnail shape. Opening a playable local video starts playback
directly. The video info sheet can show the source and generated images in a
compact comparison; tapping that preview opens a larger full-image comparison or
single-image preview depending on which images are available. These comparison
images are companion media and must not block final video save; the MP4 becomes
ready for Gallery first, then missing comparison images can be backfilled from
backend artifact metadata when available.

Current polish note: Animate AV uses `Videos` for the visible completed-media
surface while keeping `gallery` as an implementation/local-first compatibility
term. Do not rename backend/local-first media behavior blindly. Keep
`Active`/active videos for the iOS active-work surface unless a broader
terminology audit changes it.

Create Video style review note: the shipped client has 8 look families with 8
looks each, one unique preview asset per look, Look as its own focused step,
Guide and message as the next step, and synchronized runtime copy for `en`, `es`,
`ca`, `fr`, and `de`. Do not reintroduce look-to-character-voice coupling or
custom audio controls.

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
