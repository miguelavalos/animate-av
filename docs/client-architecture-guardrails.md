# Client Architecture Guardrails

Status: active public-safe rule for the Animate AV iOS client.

This repository owns the native iOS client. It does not own private backend
architecture, provider selection, pricing policy, admin operations, or secret
runtime configuration.

## Backend-Owned Workflows

Video and image generation are backend-owned. The iOS app sends user intent and
renders the state returned by the configured backend/realtime layer.

The current v1 user flow is:

```text
Foto y encuadre -> Look -> Guide and voice -> quote credits -> generate animated card -> local download -> Gallery
```

The Foto y encuadre step owns source-photo choice, full-photo use, frame
adjustment, photo replacement, and discard. Use "frame"/"encuadre" language in
Animate AV; do not expose prior-product multi-photo editing, sorting, empty
media actions, or "crop"/"recorte" as the normal visible flow.
If the user adjusts the frame, that adjusted image is the workflow source photo.
The client should retain the imported source-photo bytes locally while the draft
is editable, then derive the active workflow image from those bytes. Re-entering
frame adjustment must edit from the local original, not from a prior cropped
derivative. Restore-original is a local operation that copies the retained
original back into the active workflow image.

Frame adjustment is allowed to save a non-9:16 source reference. The default
reference frame is square for subject selection; a vertical 9:16 frame is
available for users who want video-oriented framing. The client must not fake a
vertical frame by adding black bars, blurred side/top bands, or other padding to
the active workflow image.

The backend receives only the active workflow image. Do not upload both the
local original and adjusted image in v1. If metadata is useful, it may identify
that a frame adjustment was applied, but the private backend should not be
treated as the source of truth for restoring the user's pre-adjusted photo.

Look is a separate guided step and must stay focused on visual style selection:
8 look families, 8 looks per family, and one selected look. It must not contain
animation preset cards, guide controls, voice controls, or hidden audio
choices.
The Look grid may provide a secondary preview action that opens the selected
look asset larger for inspection. That preview must not change the selected look
unless the user explicitly taps the look selection control.

The animation guide and optional voice line are collected in the next guided
sheet. The guide captures optional free-text visual direction for what should
happen in the animated scene. The voice line is a short optional line that can
be disabled with "No voice".
A valid one-photo video can be confirmed with no guide text and no voice.
Custom visual instructions are capped client-side and sent as user text only
when the user has actually typed non-empty text. Client copy must describe this
as basic, orientative guidance, not an exact command.

Create Video status cards, Avi guidance, summary rows, and fixed action bars
must follow the guided client state before backend-ready legacy state. A saved
story direction or previous fixture state is not enough to show credit review.
Credit review becomes visible only after a renderable local photo exists, the
user has selected a look/style, and the guided Guide and voice
path is complete. If the local photo data is missing or cannot decode as an
image, the client must reset visible state to Foto y encuadre and block
later-step actions.

The basic guide is a lightweight state guide, not a separate product step. It
may summarize the next required action and open the relevant guided sheet, but
it must mirror the same Photo/framing -> Look -> Guide and voice
order and must not introduce custom audio controls, preview-versioning, or
extra review branches.

Images use the same ownership model with a simpler output: choose one source
photo, generate a stylized image, then download/share it or use it as video
input when synced state allows.

There is no public generated video preview/review step and no separate image
credit currency in v1. Any intermediate styled image created inside the direct
video flow is internal backend workflow state, not a user review surface.

The iOS app must not:

- calculate video or image credit cost;
- calculate final provider route, provider capability, or final duration;
- call Convex mutations for backend-owned video jobs, image jobs, media,
  artifacts, Gallery, accounting, or workflow state;
- create or persist generation jobs as local authority;
- update generation job status;
- attach generation artifacts;
- poll backend status endpoints for normal product UI;
- treat a locally supplied owner id as sufficient authorization for realtime
  reads;
- call provider APIs directly.

The iOS app may:

- collect user media choices and setup options;
- collect client-side animation direction and send it as tolerant additional
  request metadata when supported by the backend;
- show local editing affordances before final confirmation;
- request an official backend quote/plan;
- confirm the selected backend quote/plan;
- ask the authenticated backend for a realtime session before starting
  owner-scoped subscriptions;
- subscribe to synced workspace state and generation progress, failure, and final
  artifact availability after that realtime session is available;
- download the completed final artifact to local device storage;
- move the downloaded final video or image into Gallery and clear the active
  draft/session;
- render recovered Gallery metadata separately from current-device file
  availability;
- show a temporary local loading state while waiting for synced state to arrive.

## UI Rule

After video or image confirmation, editing must lock from synced workflow state
until the generation reaches a terminal state. The user should see exactly one
clear status: waiting, creating, failed, or ready.

When the final artifact is ready, v1 shows only the download/finish path. After
finish, the creation screen closes and Gallery shows the newest finished item
first. A Gallery item may be remote metadata only until the final video or image
exists on the current device. The v1 client must not offer final-video versions
or "create another version" from the completed state.

## Local Availability Rule

Signed-in product state and local file availability are different things.

The iOS app must:

- keep backend-backed video/image state visible after sign-in when synced state
  exists;
- keep Gallery metadata visible when the local final media file is missing;
- show whether media is saved on this device, downloadable, unavailable, or
  missing locally;
- block playback/share when no local media file exists;
- validate required Photos assets before generation actions that need local
  source media.

If the app appears to need a timer or manual status loop for normal video or
image creation state, stop and review the private architecture contract before
adding code.

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

Realtime is for active workflow state and short-lived remote artifact
availability. Gallery is local-first after download. Do not keep Gallery remote
artifact subscriptions running for the full signed-in app session just because
the user is authenticated; start remote Gallery observation only when a screen
needs remote availability, and stop it when that screen no longer needs it.

## Product Terminology Review Rule

The current app still uses visible `Gallery` and `In Progress` concepts inherited
from the reusable app foundation. Before changing those labels, audit all
surface areas that depend on them: Home, bottom navigation, create completion,
Videos, Images, active jobs, local media availability, and recovery. The
underlying behavior remains: active workflow state is realtime-backed, completed
media is local-first after download, and remote artifact availability is
short-lived.

Do not use adjacent product language such as memory, moment, story, album, or
library in visible Animate AV copy unless it is a deliberate compatibility term
hidden from users.

## V1 Media Rule

V1 final videos are animated one-photo card videos. The client must not present
multi-photo sorting, album-style edit screens, audio controls, voice presets,
voice cloning, captions, subtitles, or user audio uploads as available v1
features. If future written card text is exposed, it must be a controlled
card/compositor input, not a prompt asking the model to draw readable text.

Create Video text entry should rely on the native iOS keyboard, including
system dictation when the user has it enabled. Do not add an in-app microphone
button for v1 unless the flow also adds explicit speech recognition and
microphone permissions, listening states, cancellation, error handling, and
device QA.

## Public Documentation Boundary

Keep this public repo limited to client behavior and public-safe build/test
instructions. Details about Cloudflare, Convex deployment, D1/R2 operations,
provider models, pricing policy, credits policy, admin repair flows, and
production smoke credentials belong in the private AVALSYS suite.
