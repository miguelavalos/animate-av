# Animate AV iOS

SwiftUI client for Animate AV.

This public README is intentionally limited to frontend build and test notes.
Business rules, pricing, provider/model routing, purchase setup, App Store
review handoff, and private backend operations belong in the private AVALSYS
suite.

For full local setup, see [../../docs/install-ios.md](../../docs/install-ios.md).
For client workflow ownership rules, see
[../../docs/client-architecture-guardrails.md](../../docs/client-architecture-guardrails.md).
For runtime-config hygiene, see
[../../docs/production-config.md](../../docs/production-config.md).

## Runtime Config

Committed config files keep runtime values blank or public-safe. Local and
release values are generated into ignored local config by private maintainer
tooling.

## Client Scope

The iOS app is the local source-photo selection, setup, realtime display,
download, sharing, and local Gallery surface. Backend services own quote
planning, credit costs, provider routing, generation status, artifacts, and
credit commit/release.

Current v1 flow:

```text
Choose source photo -> choose style and message -> backend infers duration and quotes credits -> generate animated video -> local download -> Gallery
```

Images are a separate v1 workflow: choose one source photo, generate a stylized
image, then download/share it or use it as video input when synced state allows.

Animate AV's default generation contract is fidelity to the user's source
photo. The client must not silently crop, zoom, reframe, or isolate a person
before upload. If a future "adjust image" step is added, the full image remains
the default, any crop must be explicitly chosen by the user, and the app should
retain enough local metadata to distinguish original image, used image, and
generated image in Gallery/Info.

Do not add a public video preview/review step, generated audio controls,
captions, subtitles, text overlays, provider/model selection, or cloud media
storage as v1 client features.

Current product-polish scope:

- Review visible `Gallery` and `In Progress` naming before production smoke; the
  behavior may stay, but the labels may not fit Animate AV.
- Review Create Video looks in English first: family names, look names,
  subtitles, and preview images.
- Keep the guided voice picker unchanged unless a concrete defect appears.
- Defer broad localization cleanup until English copy and flow are accepted.

## First Run Branding

The expected first-run sequence is:

```text
native launch logo + icon -> product splash with Avi -> onboarding
```

Verify this on a clean simulator install after changing launch assets,
storyboard/plist configuration, splash art, onboarding art, or shell bootstrap
timing. The native launch frame must show Animate AV branding, not copied
branding from another Apps AV product.

Do not commit:

- generated `Local.xcconfig`;
- production URLs or private endpoints;
- signing team IDs or provisioning material;
- client keys generated for a specific environment;
- provider, purchase, promo, or reviewer configuration.

## Build

Generate the Xcode project after editing `project.yml`:

```bash
xcodegen generate --spec apps/ios/project.yml
```

Build for simulator:

```bash
xcodebuild -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

That command is compile-only. Do not use `CODE_SIGNING_ALLOWED=NO` for signed
runtime flows. Account/session flows and end-to-end smoke tests require normal
simulator or device signing.

Validate effective runtime config after generating local settings:

```bash
scripts/check-ios-runtime-config.sh --env staging
```

For signed iPhone installs, use the helper instead of editing Xcode signing
settings into the project:

```bash
scripts/install-ios-device.sh --env staging --development-team <APPLE_DEVELOPER_TEAM_ID>
```

Use the private release runbook for production archive checks.

## Test

Run the focused simulator test suite after generating the Xcode project:

```bash
xcodebuild test -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' CODE_SIGNING_ALLOWED=NO
```
