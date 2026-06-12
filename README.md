# Animate AV

[![Public Readiness](https://github.com/miguelavalos/animate-av/actions/workflows/public-readiness.yml/badge.svg)](https://github.com/miguelavalos/animate-av/actions/workflows/public-readiness.yml)

Open-source frontend app repository for Animate AV.

Animate AV helps people start from one source photo and create either a short
animated video or a stylized image.
This public repository contains the iOS client code, public setup docs, support
policy, security policy, and client-side checks that are safe to publish.

It intentionally excludes credentials, signing material, production runtime
values, private backend implementation, provider/model policy, pricing strategy,
App Store review handoff material, promo codes, and internal business planning.

Before validating signed account, credit, upload, render, billing, or deletion
workflows, read [AGENTS.md](AGENTS.md). Those workflows are governed by private
AVALSYS runbooks and must not be replaced with an invented local backend flow.

## Repository Shape

```text
apps/
  ios/      SwiftUI iOS app
docs/
  README.md
  install-ios.md
  production-config.md
  client-architecture-guardrails.md
  release-checklist.md
  release-evidence-template.md
  canonical-asset-handoff.md
  look-preview-assets.md
```

The current public product shape is a one-photo creation flow:

```text
Photo / Frame -> Look -> Movement -> optional Message / Voice -> Check cost -> Create video -> local download -> Gallery
```

Generated images are a separate source-photo workflow. Public docs should not
describe inherited multi-photo editing, provider/model routing, pricing
strategy, or generated video preview/versioning as Animate AV client features.

## Local Setup

See [docs/install-ios.md](docs/install-ios.md) for local iOS setup.

Quick compile check:

```bash
xcodegen generate --spec apps/ios/project.yml
xcodebuild -project apps/ios/AnimateAV.xcodeproj -scheme AnimateAV -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Use unsigned builds only for compile checks. Authenticated runtime flows need
normal simulator or device signing and local runtime configuration generated
outside this public repo.

Before opening a pull request, run:

```bash
scripts/check-public-hygiene.sh
```

Before an App Store release candidate, run the full release readiness check:

```bash
scripts/check-public-release-readiness.sh
```

## Contributing And Security

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security policy: [SECURITY.md](SECURITY.md)
- Support policy: [SUPPORT.md](SUPPORT.md)

## License

This repository is released under the MIT license. See [LICENSE](LICENSE).
