# Install Animate AV iOS

This guide covers local setup for the public Animate AV iOS client. It does not
include production credentials, private provider setup, App Store Connect
operations, pricing, or business configuration.

## Requirements

- Xcode with the iOS SDK used by the project.
- XcodeGen available on `PATH`.
- Access to the sibling public `account-av` checkout at the expected workspace
  path.
- Private runtime access only when testing signed-in flows.

## Generate The Xcode Project

Run from the repository root:

```bash
xcodegen generate --spec apps/ios/project.yml
```

Re-run this command after changing `apps/ios/project.yml`.

## Public Compile Check

The committed configs intentionally leave runtime endpoints and publishable
client keys blank. A public simulator build can still compile without signing:

```bash
xcodebuild -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'generic/platform=iOS Simulator' -derivedDataPath .DerivedData-public-compile CODE_SIGNING_ALLOWED=NO build
```

This verifies the app compiles. Do not use this unsigned build for sign-in,
account, purchase, upload, render, or deletion smoke tests. Those flows require
normal simulator or device signing and local runtime configuration generated
outside this public repo.

## Local Runtime Config

Runtime config is generated into:

```text
apps/ios/Config/Local.xcconfig
```

That file is intentionally gitignored and must not be committed.

Generate and validate local runtime config through the private AVALSYS tooling
available to maintainers. Public docs should describe the hygiene rules, not
the production values. See [production-config.md](production-config.md).

For signed development smoke, generate the `staging` runtime config. In AVALSYS
Apps AV projects, `staging` means deployed preview. Do not point Animate AV at a
local Wrangler API worker for sign-in, credits, media upload, render-plan,
final-render, gallery, purchase, or account-deletion testing. Use Convex cloud
`dev`, not local Convex, for the same workflow validation.

After generating local settings, validate the effective build settings:

```bash
scripts/check-ios-runtime-config.sh --env staging
```

Use the environment required by the private release runbook when preparing a
signed release or App Store archive.

For TestFlight parity, use production runtime settings:

```bash
scripts/generate-ios-local-xcconfig.sh --env prod
scripts/check-ios-runtime-config.sh --env prod --configuration Release
```

The check must report the production bundle identifier, production Account AV
API, a production Account AV publishable key class, and the expected RevenueCat
offering before building an archive. If it reports `staging`, the resulting
build may compile and upload but signed-in production auth can fail.

## Signed Runtime Smoke

For any flow that depends on a real account session, build and launch without
`CODE_SIGNING_ALLOWED=NO`:

```bash
xcodebuild -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .DerivedData-signed-smoke build
```

Do not diagnose onboarding, Sign in with Apple, Google OAuth, persisted sessions,
credits, purchases, uploads, renders, or account deletion from an unsigned build
or from a simulator install that previously ran an unsigned build. Those states
can report false auth/keychain failures even when production runtime config is
correct.

When testing the production/TestFlight workflow on simulator, use a normal
signed Release simulator build after generating the production local config.
This does not replace real-device TestFlight purchase testing, but it should
match the production Account AV environment closely enough to catch auth
configuration drift before upload.

Before any auth smoke after unsigned testing, remove stale app state before
reinstalling a signed simulator build:

```bash
xcrun simctl uninstall booted com.avalsys.animateav.dev
xcrun simctl uninstall booted com.avalsys.animateav
```

Then rebuild with simulator signing enabled.

## Real Device Install

Use the device helper for signed iPhone installs. It regenerates local runtime
config, validates effective settings for the selected device, builds, installs,
and launches the app:

```bash
scripts/install-ios-device.sh --env staging --development-team <APPLE_DEVELOPER_TEAM_ID>
```

Use `--device <UDID>` when more than one iPhone is connected. Use
`--configuration Release --env prod` only when following the private release
runbook.

The `--development-team` value is a local Xcode CLI override for machines where
Xcode UI can sign the app but `xcodebuild` reports `No Account for Team` or no
matching provisioning profile. Do not commit that team id, change shared
Infisical config, or edit `project.pbxproj` to work around a local Xcode account
resolver issue.

## Tests

Run the focused simulator test suite after generating the Xcode project:

```bash
xcodebuild test -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -derivedDataPath .DerivedData-tests CODE_SIGNING_ALLOWED=NO
```

If the requested simulator is unavailable, pick an installed iPhone simulator
and keep the destination explicit.

## Local Build Cache Cleanup

Xcode `DerivedData` can grow by several gigabytes per build/test profile. Keep
agent-owned build output repo-local and purpose-named with `-derivedDataPath`
as shown above, then remove it after the validation run is no longer needed.

Measure first:

```bash
find . -type d \( -name '.DerivedData*' -o -name '.derived-data*' -o -name 'DerivedData' \) -prune -print0 | xargs -0 du -sh
```

Clean only when no active build is using those directories:

```bash
find . -type d \( -name '.DerivedData*' -o -name '.derived-data*' -o -name 'DerivedData' \) -prune -print0 | xargs -0 rm -rf
```

## Public Config Hygiene

Before committing, run:

```bash
scripts/check-public-hygiene.sh
```

This blocks tracked local configs, local worker URLs, development team IDs,
secret-looking keys, and broken public Markdown links.

Before an App Store release candidate, run:

```bash
scripts/check-public-release-readiness.sh
```

That full release check also blocks accidental final artwork that has not passed
the public asset gate.
