# Animate AV Public Release Checklist

Status: public repository readiness checklist.

This file is for code and documentation hygiene in the public iOS repository.
App Store Connect metadata, review notes, privacy answers, promo codes,
pricing, provider/model decisions, and final submission decisions are maintained
in the private AVALSYS suite.

## Public Repo Gate

- [ ] `xcodegen generate --spec apps/ios/project.yml` succeeds.
- [ ] The public compile check succeeds with unsigned simulator build settings.
- [ ] For TestFlight/App Store handoff, the private production local config has
  been generated and `scripts/check-ios-runtime-config.sh --env prod
  --configuration Release` passes before archive/upload.
- [ ] Auth, account, credit, purchase, upload, render, and deletion smokes use a
  signed install. Any simulator that previously ran an unsigned build has had
  both `app.avalsys.animateav.dev` and `app.avalsys.animateav` uninstalled
  before the signed smoke.
- [ ] Focused tests pass or failures are documented in the private handoff.
- [ ] `scripts/check-public-hygiene.sh` passes for normal public repo changes.
- [ ] `scripts/check-public-release-readiness.sh` passes before App Store release
  candidate handoff.
- [ ] No generated local config is tracked.
- [ ] No signing material, provisioning profiles, team IDs, keys, tokens, or
  private URLs are tracked.
- [ ] Public Markdown links are valid.
- [ ] Public screenshots, if any, contain no private user data, account data,
  request IDs, receipts, or internal logs.
- [ ] Final icons, splash assets, AV marks, and Avi artwork are added only after
  the public canonical asset gate is updated.

## Safe Public Evidence

Public release evidence may record:

- command names and pass/fail result;
- Xcode version and SDK version;
- simulator model and OS;
- public commit SHA;
- public artifact paths that contain no private data.

Public release evidence must not record:

- App Store reviewer accounts or passwords;
- promo codes or campaign details;
- pricing, credit grants, margins, or product strategy;
- production backend URLs or provider/model configuration;
- Apple, RevenueCat, account, or provider console data;
- private screenshots, selected media, generated videos, receipts, or logs.

Use [release-evidence-template.md](release-evidence-template.md) for the public
technical evidence shape.

## Private Handoff

Before App Store submission, complete the private release package covering:

- App Store metadata and screenshots;
- App Privacy answers;
- App Review notes;
- purchase and subscription setup;
- account deletion verification;
- provider/model and retention policy checks;
- final legal/privacy approval.
