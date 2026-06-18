# Animate AV Web Audit

Status: current as of 2026-06-18.

Animate AV commercial web was checked as part of the AV web visual audit.
Animate AV app web now exists at `apps/web`.

## Contract

- User-facing web content supports `en`, `es`, `fr`, `de`, and `ca`.
- AV-owned links preserve the active language.
- The commercial surface may use AVALSYS naming where legal, brand, or company
  context requires it.
- App web has a public informational `/` route.
- App web product routes require login; no guest-mode product functionality is
  exposed on web.
- App web runs on app origins: preview
  `https://app.animate-av-preview.avalsys.com` and production
  `https://app.animate-av.avalsys.com`.

## Latest Audit Result

- Desktop and mobile browser QA passed.
- Footer links to AV-owned surfaces preserve language.
- Commercial metadata and Avi asset presentation were polished during the
  audit.
- Local and preview app web QA passed for public `/`, protected `/create`, and
  five-language rendering.
- Preview app web deployed to `https://app.animate-av-preview.avalsys.com`.
- The preview app web build no longer emits the large client chunk warning:
  vendor chunks are split for Clerk, serialization, UI, and app bootstrap while
  keeping the same public `/`, sign-in, and protected-route behavior.
