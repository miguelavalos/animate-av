# Animate AV Agent Rules

This public repo does not define the full signed-runtime testing workflow.

For any native app workflow validation that touches signed account state,
credits, uploads, Convex, render plans, final renders, artifacts, purchases,
billing, or deletion flows, follow the private AVALSYS guide. Do not invent a
local runtime flow from this public repo.

- `private/avalsys-suite/docs/platform/native-preview-dev-validation-guide.md`
- `private/avalsys-suite/docs/animate-av/preview-dev-validation-guide.md`
- `private/avalsys-suite/docs/animate-av/create-video-workflow-validation-2026-06-11.md`
- `private/avalsys-suite/docs/agents/plan-step.md` when the user says
  `usa plan-step` or asks for step-by-step plan execution.
- `private/avalsys-suite/docs/agents/plan-goal.md` when the user says
  `usa plan-goal` or asks for reviewed full-plan execution.

Mandatory rules:

- use Cloudflare preview for API runtime;
- use Convex cloud `dev`, not local Convex;
- do not use `wrangler dev` or another local Worker as product app backend;
- do not invent alternate runtime/testing flows when the private guide already
  defines one;
- use Infisical/Varlock-backed private tooling for config, deploy keys, and
  secret resolution;
- use the mock final-render route for no-spend validation unless private docs
  explicitly approve a paid provider smoke;
- treat "no-spend" as "no paid provider call", not "skip user credit workflow";
- for Animate AV v1, the final flow is create final video -> download -> finish
  -> Gallery. Do not add preview/versioning branches in this public app.
- treat Convex realtime as active workflow state or short-lived remote artifact
  availability. Gallery is local-first after download; do not start global
  Gallery remote subscriptions for the whole signed-in app session.
- do not unblock stuck UI by requiring users or agents to manually delete
  Convex/D1 rows. If a run can get stuck in queued/running, the fix belongs in
  backend timeout/failure handling, idempotent replay, credit release, or
  scheduled cleanup.
- no-spend workflow tests must still exercise quote/check-cost, credit
  confirmation, queued/running/completed UI states, final artifact handoff, and
  Gallery cleanup. Only the paid provider call is mocked.
- in the final video flow, `/renders/plan` is the source of truth for cost,
  blockers, watermark choice, and the subsequent confirmation. Do not add a
  separate `/video/quotes` preflight inside Check cost/Create video; it creates
  duplicate loading states and can desynchronise UI from the confirmable plan.
- before adapting this workflow to Moments AV or another app, read the
  2026-06-11 create-video validation closeout and preserve the generic contract:
  plan first, confirm second, durable backend workflow ownership, short-lived
  Convex projection, and local-first Gallery after download.
- before declaring the create-video workflow done, validate controlled failure
  paths: provider failure, stale plan, insufficient credits, offline/unavailable
  backend, final artifact missing, and retry. The UI must recover without a
  permanent loader or hidden manual cleanup.
- after finishing to Gallery, the create screen must be clean enough to start a
  new video. If a tap on the result thumbnail and a tap on the finish button both
  navigate to Gallery, both paths must clear the final-session state.
- keep tests aligned with product copy. If `Localizable.strings` changes, update
  presentation tests in the same change instead of leaving stale expectations.
- when changing loaders or sheets, run the relevant view-model/presentation tests
  and manually inspect the simulator transition. The previous failure mode was a
  visually nicer loader that hid broken sheet/state behavior.

If the private repo is unavailable, stop and say that the authoritative runbook
cannot be checked. Do not substitute a guessed local workflow.
