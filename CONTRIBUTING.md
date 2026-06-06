# Contributing

## Scope

This repository contains the open-source frontend app for Animate AV.

Contributions are welcome for:

- SwiftUI UI improvements;
- accessibility;
- localization;
- bug fixes;
- public documentation improvements.

## Before Opening A PR

1. Keep changes focused and small when possible.
2. Make sure the app still builds locally when app code exists.
3. Update public docs if setup or user-facing behavior changes.
4. Do not commit local config, secrets, signing material, or generated files.
5. Run the public readiness checks:

```bash
scripts/check-public-release-readiness.sh
```

These checks verify public config hygiene, Markdown links, and the canonical
asset gate.

## Branding And Assets

- Do not commit App Store icons, splash assets, AV monograms, or Avi artwork
  unless they come from approved canonical assets.
- Do not use generated, approximate, or placeholder AV marks.
- Avi is the in-app assistant, not the product logo or app icon.
- App Store screenshots must show real submitted app UI and shipped behavior.

## Pull Requests

- Use clear commit messages.
- Describe user-facing behavior changes.
- Mention any manual test steps you ran.
- If a change touches config or signing behavior, call that out explicitly.

## Issues

- Use issues for bugs, usability problems, accessibility problems, and focused
  feature requests.
- For security issues, do not open a public issue. Follow `SECURITY.md`.
