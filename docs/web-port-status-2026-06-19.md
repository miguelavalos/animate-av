# Animate AV Web Port Status - 2026-06-19

This note records the current public web-port state after the Animate AV iOS
parity pass. It is intentionally client-safe: it does not include secrets,
operator tokens, private deployment details, or paid-provider instructions.

## Guardrails Followed

- Ran the private Animate AV preflight for code work.
- Read the required workspace, public repo, production simulator loop, and
  create-video workflow validation runbooks before implementation.
- Did not run paid provider calls, final live renders, payment flows, deploys,
  local Wrangler, or local Convex product backends.
- Treated no-spend as "no paid provider call", not as permission to skip the
  signed credit/render workflow. Signed workflow smoke remains pending because
  no approved signed-in smoke token was present in the environment.
- Preserved the Animate AV V1 constraint: no visible voice, narrator, tone,
  generated-audio, language, duration, or in-app audio controls.

## Implemented In `apps/web`

### Account, API, And Runtime Wiring

- Added an Animate API client that obtains Account AV tokens and calls approved
  Animate endpoints for credits, media upload, render plan, final confirm,
  artifact download, rename, and delete.
- Added configuration helpers for Account AV, Animate API, credits URL, and
  optional Convex URL.
- Added Convex provider/session wiring that stays inert when Convex is not
  configured.
- Added localized API error handling so backend English/details are not shown
  raw in the UI.
- Added signed media URL and method validation before browser upload/download
  calls.

### Create Video

- Protected `/create` behind Account AV.
- Implemented one-source-image flow with validation for JPG/JPEG, PNG, HEIC,
  HEIF, and WebP, plus a 25 MB limit.
- Added full-image default framing and explicit 9:16 portrait-frame generation.
- Added upload prepare, signed upload, completion, and source metadata hashing.
- Added Look step with 8 families x 8 looks and copied preview assets.
- Kept Animation as a separate step with one short optional guidance field.
- Added optional written Message/Dedication field without voice/audio controls.
- Added setup summary and render review.
- Uses `/v1/apps/animateav/renders/plan` as the single source of cost, blockers,
  watermark, and confirmable plan state.
- Confirms final render once with a stable idempotency key and local in-flight
  guard.
- Blocks final confirmation when the plan is stale or not creatable.
- Stores local in-progress fallback state after final confirm submission.

### In Progress

- Added protected `/in-progress`.
- Merges Convex realtime jobs with local submitted jobs.
- Deduplicates local/realtime jobs by id, video id, render job id, and workflow
  run id.
- Shows queued/running/completed counts and localized job status labels.
- Supports rename/delete for realtime jobs where backend commands are exposed.
- Supports clearing local fallback jobs without backend deletion.

### Gallery

- Added protected `/gallery`.
- Keeps Gallery local-first after download.
- Stores downloaded final video blobs in browser IndexedDB and metadata in
  localStorage.
- Rehydrates object URLs on load and revokes stale URLs on replacement/unmount.
- Shows short-lived remote final video artifacts from Convex only when available
  and not already saved locally.
- Keeps remote download visible when local metadata exists but the local file is
  missing.
- Supports local rename, local clear, and final artifact download.
- Broadcasts same-tab and cross-tab local gallery changes.

### Avi

- Added protected Avi guidance route using Account AV state.
- Shows credit balance without treating loading as zero.
- Shows local downloaded video count and updates on same-tab/cross-tab Gallery
  changes.
- Shows active work from the same realtime + local merge used by In Progress.
- Reduced visible CTA clutter: Create remains primary, In Progress is secondary,
  and Gallery/local videos are represented as state.

### Home, Sign-In, Protected Gate, And Dark Mode

- Kept `/` public and informational.
- Kept `/create`, `/gallery`, `/avi`, and `/in-progress` protected.
- Added dark-mode tokens and dark variants across touched surfaces.
- Simplified secondary actions in Gallery and In Progress into compact menus.
- Fixed `/sign-in` mobile horizontal overflow.
- Reserved stable sign-in auth area height to reduce layout shift.
- Added visible focus treatment for app links/buttons.
- Increased shared Apps AV footer language/link touch targets in the installed
  local dependency to at least 40 px.

### Localization

- Added/updated English, Spanish, French, German, and Catalan copy for the web
  port.
- Added tests that block reintroducing voice, narrator, or audio-control copy.
- Preserved `?lang` behavior for localized app paths.

### Tests

Added web tests for:

- API render payload normalization and no-spend controls.
- Signed media URL/method validation.
- Source image validation and generated filename extension handling.
- Render plan state, stale-plan detection, idempotency, credit loading, and
  blocker summarization.
- Local Gallery storage, blob hydration, missing local file recovery, remote
  artifact availability, and cross-tab/same-tab events.
- Local In Progress storage/events and realtime/local merge dedupe.
- Look family matrix and preview asset coverage.
- Localized paths and forbidden voice/audio visible copy.

## Validation Completed

Commands run successfully:

```sh
bun test
bun run web:typecheck
bun run web:build
```

Latest observed unit result:

- 55 tests passing.
- 0 failures.

Browser/no-spend checks performed with Expect:

- Public `/`, `/sign-in`, protected `/avi`, `/create`, `/gallery`, and
  `/in-progress` were checked signed out.
- Protected routes stayed behind the account gate.
- No upload, render-plan, final-confirm, credit/payment, or provider endpoints
  were intentionally triggered.
- Mobile and desktop dark-mode checks passed for protected gate rendering,
  overflow, language switching, and touch target size after dependency refresh.
- WebKit checks were skipped because the local Playwright WebKit executable was
  not installed.

## Known Pending Work

### Requires Approved Signed Runtime

- Signed-in no-spend smoke is still pending. It requires an approved short-lived
  signed-in smoke token in the operator environment.
- The signed smoke must exercise the real account/credit workflow without a
  paid provider call: upload preparation, signed upload, `/renders/plan`,
  credit confirmation, final confirm, queued/running/completed state, artifact
  handoff, download, and Gallery cleanup.
- No live paid provider smoke has been run in this pass. Do not run one without
  explicit owner approval.

### Browser QA Still Pending

- Full signed-in Create flow QA across en/es/fr/de/ca.
- Desktop/mobile QA for the authenticated Create wizard, In Progress, Gallery,
  Avi state cards, and final artifact download.
- WebKit/Safari-equivalent QA once Playwright WebKit is installed.
- Final accessibility audit cleanup. Manual checks observed visible focus and
  >=40 px touch targets on the protected gate, but IBM Equal Access still
  reported focus-visible/style violations in one interrupted run. The focus
  styles should be tokenized and re-audited.

### UI/Product Polish

- Continue reducing visible secondary buttons where web surfaces still feel
  tool-heavy, while keeping all required actions available.
- Replace remaining hardcoded visual colors in touched UI with design-system
  tokens where practical.
- Review inherited "Gallery" and "In Progress" terminology before changing
  labels; current web nav uses "Videos" for Gallery and keeps "In Progress" for
  active work.
- Signed-in Home can be improved further with account-aware summary cards, but
  it must not start global Gallery remote subscriptions for the whole session.

### Runtime/Recovery

- Backend stuck-state recovery was not changed in this pass. Do not resolve
  queued/running failures by manual row deletion; fixes belong in backend
  timeout/failure/idempotent replay/credit release paths.
- Convex remains short-lived workflow/artifact projection, not durable Gallery
  storage.

## Safety Note

No real money was spent in this pass. No paid provider render, credit purchase,
payment flow, deploy, TestFlight upload, or production write was executed.
