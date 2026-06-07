# Animate AV Canonical Asset Handoff

Status: required before adding or changing final App Store icon, launch logo,
splash, onboarding, AV monogram usage, Avi artwork, or framed screenshot assets
in this public repo.

Do not use this document to approve generated, approximate, or exploratory
artwork. It is a handoff record for already-approved canonical assets.

## Current Status

Animate AV follows the shared Apps AV first-run branding pattern:

```text
native launch logo + icon -> product splash with Avi -> onboarding
```

Any public PR that adds or replaces final runtime assets must record the exact
approved package below. Do not import exploratory Animate AV logo, mark,
concept, or icon files from private brand working folders as final App Store
assets without updating this handoff.

## Asset Package

- Package name:
- Date:
- Owner:
- Reviewer:
- Approval reference:
- Source location:
- Export location:
- Intended release:

## Included Assets

Record every file before adding it to the repo.

```text
Asset:
Repo path:
Type: app icon / splash / AV monogram / Avi artwork / screenshot frame / other
Source file:
Export size:
Format:
Checksum:
Purpose:
Approved: yes/no
Notes:
```

## Required Rules

- [ ] App icon source is approved for Animate AV.
- [ ] Native launch logo source is approved for Animate AV.
- [ ] Splash artwork source is approved for Animate AV.
- [ ] Onboarding artwork source is approved for Animate AV.
- [ ] Splash artwork shows Avi as a useful assistant, not as the app icon.
- [ ] Onboarding artwork does not duplicate Avi when Avi is already rendered
  near the primary call-to-action.
- [ ] Splash and onboarding artwork integrate with the app background without
  visible rectangular canvas edges.
- [ ] Any embedded AV mark uses the canonical AVALSYS monogram.
- [ ] AV mark is small and secondary, not the primary product icon.
- [ ] Avi is not used as the app icon, product logo, or wordmark.
- [ ] Avi artwork appears only where the submitted app actually shows Avi.
- [ ] Screenshots show real release-candidate UI.
- [ ] No screenshot frame hides legal, account, credit, deletion, or export
  state copy.
- [ ] No generated or approximate AV marks are present.
- [ ] No archived/experimental Avi explorations are used as production sources.

## Verification

Before opening the asset PR:

- [ ] Compare app icon at small home-screen sizes.
- [ ] Compare App Store icon at full resolution.
- [ ] Clean-install the app and verify native launch, splash, and onboarding
  appear in order.
- [ ] Confirm native launch shows Animate AV logo plus icon, not copied branding
  from another Apps AV app.
- [ ] Confirm splash and onboarding use product-specific Animate AV artwork.
- [ ] Confirm dark/light appearance where relevant.
- [ ] Confirm Reduce Transparency/Increase Contrast do not break app UI around
  the asset.
- [ ] Confirm screenshots contain no private user data.
- [ ] Confirm App Store metadata and screenshot captions match the visible UI.
- [ ] Run public readiness checks after integrating the approved assets.

```bash
scripts/check-public-release-readiness.sh
```

## Gate Update

The current public canonical asset gate is intentionally strict. When approved
assets are ready, update the gate and this handoff together so CI allows only
the approved repo paths.

Do not bypass the gate by renaming assets to avoid icon, splash, AV, monogram,
or Avi checks.
