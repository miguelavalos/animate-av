# Client Architecture Guardrails

Status: active public-safe rule for the Animate AV iOS client.

This repository owns the native iOS client. It does not own private backend
architecture, provider selection, pricing policy, admin operations, or secret
runtime configuration.

## Backend-Owned Workflows

Final video creation is backend-owned. The iOS app sends user intent and renders
the state returned by the configured backend/realtime layer.

The current v1 user flow is:

```text
Choose moments -> edit options -> Create video -> confirm credits -> final render -> local download -> Gallery
```

There is no public generated preview step and no separate Story Review currency
in v1. Story preparation is internal planning support for final render.

The iOS app must not:

- calculate final video credit cost;
- calculate final provider route, provider capability, or final duration;
- call Convex mutations for backend-owned Moment, media, story, render,
  artifact, Gallery, or workflow state;
- create or persist final render jobs as local authority;
- update final render job status;
- attach final render artifacts;
- poll backend status endpoints for normal product UI;
- treat a locally supplied owner id as sufficient authorization for realtime
  reads;
- call provider APIs directly.

The iOS app may:

- collect user media choices and setup options;
- show local editing affordances before final confirmation;
- request an official backend render plan;
- confirm the selected backend render plan;
- ask the authenticated backend for a realtime session before starting
  owner-scoped subscriptions;
- subscribe to synced workspace state and render progress, failure, and final
  artifact availability after that realtime session is available;
- download the completed final artifact to local device storage;
- move the downloaded final video into Gallery and clear the active
  Create draft/session;
- render recovered Gallery metadata separately from current-device file
  availability;
- show a temporary local loading state while waiting for synced state to arrive.

## UI Rule

After final video confirmation, editing must lock from synced workflow state
until the final render reaches a terminal state. The user should see exactly one
clear status: waiting, creating, failed, or ready.

When the final video is ready, v1 shows only the download/finish path. After
finish, the Create screen closes and Gallery shows the newest finished video
first. A Gallery item may be remote metadata only until the final video exists
on the current device. The v1 client must not offer final-video versions or
"create another version" from the completed state.

## Local Availability Rule

Signed-in product state and local file availability are different things.

The iOS app must:

- keep backend-backed Moments visible after sign-in when synced state exists;
- keep Gallery metadata visible when the local final video file is missing;
- show whether a video is saved on this device, downloadable, unavailable, or
  missing locally;
- block playback/share when no local video file exists;
- validate required Photos assets before final-render actions that need local
  source media.

If the app appears to need a timer or manual status loop for final video
creation, stop and review the private architecture contract before adding code.

## Realtime Subscription Rule

Owner-scoped realtime reads must be established in this order:

1. Account AV session is available.
2. A bearer token is available.
3. The authenticated backend creates a realtime session for the current user.
4. The app stores that realtime session locally in memory.
5. The app starts Convex subscriptions with the current owner id and the
   backend-issued realtime session.

On sign-out or account change, the app must clear the local realtime session and
stop owner-scoped subscriptions before observing the next user.

The client should fail closed if no realtime session is available. Do not add a
fallback that subscribes with only an owner id.

## V1 Media Rule

V1 final videos are animated one-photo videos with audio. The client must not present
generated audio, narration, voiceover, voice cloning, music, captions,
subtitles, text overlays, or user audio uploads as available v1 features.

## Public Documentation Boundary

Keep this public repo limited to client behavior and public-safe build/test
instructions. Details about Cloudflare, Convex deployment, D1/R2 operations,
provider models, pricing policy, credits policy, admin repair flows, and
production smoke credentials belong in the private AVALSYS suite.
