# Animate AV Public Release Evidence Template

Status: public technical evidence template.

Copy this only when the evidence is safe for the public repo. Keep App Store
Connect fields, review notes, promo codes, pricing, provider/model details,
production URLs, credentials, receipts, user media, generated videos, and
private logs in the private release handoff.

Suggested copy name:

```text
docs/release-evidence-public-YYYY-MM-DD.md
```

## Candidate

- Date:
- Owner:
- Public commit SHA:
- Version:
- Build:
- Xcode version:
- iOS SDK:
- Simulator/device used:

## Public Checks

Record command result:

```bash
scripts/check-public-hygiene.sh
scripts/check-public-release-readiness.sh
```

- Result:
- Notes:

## Build

Record command and outcome:

```bash
xcodebuild -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

- Result:
- Public-safe log or artifact path:

## Tests

Record command and outcome:

```bash
xcodebuild test -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' CODE_SIGNING_ALLOWED=NO
```

- Result:
- Test count:
- Failure count:
- Public-safe `.xcresult` path:

## Manual Public QA

- [ ] App launches in a simulator build safe for public QA.
- [ ] Create Video no-spend smoke reaches Foto y encuadre, Estilo y animación,
  optional written Dedication, and final confirmation
  with synthetic or fixture media only.
- [ ] Runtime localization lint/key parity passes for `en`, `es`, `ca`, `fr`,
  and `de`.
- [ ] Animation accepts custom visual instructions and the final summary
  preserves them separately from any written Dedication.
- [ ] Foto y encuadre smoke covers choose photo, adjust frame, re-enter frame
  adjustment from the locally retained original, restore original when
  available, change photo, and continue to Look without hidden sheets or paid
  provider calls.
- [ ] The normal Create Video path does not show inherited multi-photo editing,
  sorting, empty media actions, or visible `Crop` language.
- [ ] No debug URLs, local config, tokens, account identifiers, receipts, or
  private user data appear in visible UI.
- [ ] Public setup docs match the current repository shape.
- [ ] Public support and security docs are reachable.
- [ ] Public screenshots, if included, use synthetic or approved sample data.

Notes:

- Device:
- OS:
- Locale:
- Appearance:
- Result:

## Final Public Decision

- Public repo ready: yes/no
- Decision owner:
- Decision date:
- Remaining public blockers:
- Private release handoff reference:
