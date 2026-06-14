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
- [ ] Release archive/upload follows the shared Tune AV pattern: repair
  `Sentry.framework.dSYM` inside the `.xcarchive`, verify matching app and
  Sentry dSYM UUIDs, and only then export/upload. Do not accept a missing Sentry
  dSYM warning as a completed release.
- [ ] Account AV login matches the Tune AV signed iOS pattern: publishable key,
  keychain service, and keychain access group are exposed in runtime config,
  passed into Account AV/Clerk setup, and validated before TestFlight.
- [ ] Auth, account, credit, purchase, upload, render, and deletion smokes use a
  signed install. Any simulator that previously ran an unsigned build has had
  both `com.avalsys.animateav.dev` and `com.avalsys.animateav` uninstalled
  before the signed smoke.
- [ ] Focused tests pass or failures are documented in the private handoff.
- [ ] Create Video no-spend smoke reaches
  `Foto y encuadre -> Look -> Animation -> optional Message / Voice -> confirmation`
  using fixture/mock final-render routes, with no paid provider calls.
- [ ] Foto y encuadre smoke covers choose photo, adjust frame, re-enter frame
  adjustment from the locally retained original, restore original when
  available, change photo, and continue to Look without hidden sheets or paid
  provider calls.
- [ ] `scripts/check-public-hygiene.sh` passes for normal public repo changes.
- [ ] `scripts/check-public-release-readiness.sh` passes before App Store release
  candidate handoff.
- [ ] No generated local config is tracked.
- [ ] No signing material, provisioning profiles, team IDs, keys, tokens, or
  private URLs are tracked.
- [ ] Public Markdown links are valid.
- [ ] Public copy hygiene passes: no legacy credit phrasing, technical photo
  wording, or copied prior-product naming in public app copy/docs.
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
