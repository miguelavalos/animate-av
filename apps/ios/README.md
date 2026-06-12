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
Photo / Frame -> Look -> Animation -> optional Message / Voice -> backend infers duration and quotes credits -> generate animated video -> local download -> Gallery
```

Photo / Frame is the normal source-photo step. It lets the user choose one
photo, keep the full photo, adjust the frame, change photo, or discard the
draft. Do not route the normal Animate AV path through inherited multi-photo
editing, sorting, empty media actions, or visible `Crop` language.

The Photo / Frame step owns the local source-photo decision. The iOS draft
should keep the imported photo bytes as local-only original data and derive the
active workflow image from them. Frame adjustment updates only the active image;
re-entering frame adjustment should start from the local original, not from a
previously cropped derivative. Restore-original behavior is local UI state and
must not require backend recovery.

Animation is separate from Message / Voice. It captures optional visual
direction for what the image should do when it comes alive. Users may choose no
extra direction, start from a visual template, or type custom visual
instructions. Message and Voice remain optional, and a one-photo video with no
message and no narration is a valid v1 setup.

Images are a separate v1 workflow: choose one source photo, generate a stylized
image, then download/share it or use it as video input when synced state allows.

Animate AV's default generation contract is fidelity to the user's source
photo. The client must not silently crop, zoom, reframe, or isolate a person
before upload. The full image remains the default unless the user explicitly
chooses Adjust frame, and that adjusted image becomes the source photo for the
workflow.

Upload and backend generation receive only the active image selected by the
user: either the unadjusted source photo or the saved frame adjustment. Do not
upload the local original copy alongside the active image in v1. The original
copy exists only to support local editing, restore-original, and repeat
adjustment flows before the user confirms paid backend work.

Do not add a public video preview/review step, generated audio controls,
captions, subtitles, text overlays, provider/model selection, or cloud media
storage as v1 client features.

Current product-polish scope:

- Review visible `Gallery` and `In Progress` naming before production smoke; the
  behavior may stay, but the labels may not fit Animate AV.
- Keep Create Video aligned to Photo / Frame, Look, Animation, optional
  Message / Voice. Avoid reintroducing
  inherited multi-photo edit surfaces in the normal path.
- Treat Animation as visual guidance for action, camera, and scene
  behavior. It may be longer than the narrated Message and works without Voice.
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
