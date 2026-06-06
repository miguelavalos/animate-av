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
- [app-store-screenshots.md](app-store-screenshots.md): public screenshot safety
  rules for non-secret captures.

## Current Public Product Shape

V1 is a signed-in memory-video workflow:

```text
Choose moments -> edit options -> Create video -> confirm credits -> final render -> local download -> Gallery
```

The public client should not describe a generated preview step, a Story Review
balance, model/provider choices, generated audio, captions, subtitles, text
overlays, or permanent cloud video storage as v1 features.

Backend-backed in-progress Moments and finished Gallery metadata may recover
after sign-in. Local video files remain device-local availability: a Gallery
item can exist while its video file is missing on the current device, and
redownload is offered only when the backend reports an available final artifact.

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
