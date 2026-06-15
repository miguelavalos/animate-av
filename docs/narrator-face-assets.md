# Narrator Face Assets

Status: historical asset provenance. Animate AV V1 is no longer a voice product;
user-facing narrator, TTS, and voice-tone controls should stay hidden or
disabled. Keep this document only to explain older asset/test provenance.

Animate AV previously used adult voice-over narrators only. The voice-over was
an off-screen message track; it was not a character voice for people in the
photo.

The asset catalog still contains older narrator portraits because historical
look previews were generated from those references. They are kept as asset
provenance, not as the current runtime voice selector contract.

## Canonical Profiles

| Voice profile | Asset catalog image | Intended identity |
| --- | --- | --- |
| `childGirl` | `VoiceChildGirl` | Child girl |
| `childBoy` | `VoiceChildBoy` | Child boy |
| `teenGirl` | `VoiceTeenGirl` | Teen girl |
| `teenBoy` | `VoiceTeenBoy` | Teen boy |
| `adultWoman` | `VoiceAdultWoman` | Adult woman |
| `adultMan` | `VoiceAdultMan` | Adult man |
| `elderWoman` | `VoiceElderWoman` | Older woman |
| `elderMan` | `VoiceElderMan` | Older man, clearly 75-85 |

## Former Runtime Voices

The former selector used:

| Voice profile | Asset catalog image | Runtime role |
| --- | --- | --- |
| `narratorWoman` | `VoiceAdultWoman` | Female voice-over |
| `narratorMan` | `VoiceAdultMan` | Male voice-over |

## Generation Requirements

- Use a square reference portrait, at least `1024x1024`, exported to `512x512` for the asset catalog.
- Frame as head and shoulders, not full body.
- Keep eyes around 38-42% from the top of the canvas.
- Leave enough padding around hair, ears, chin, and shoulders for a circular avatar crop.
- Use consistent natural daylight, a warm off-white wall or courtyard background, and subtle greenery.
- Avoid side bands, pillarbox margins, watermarks, text, sunglasses, hats, busy backgrounds, and cropped heads.
- Runtime narrator portraits may still exist for historical tests or archived
  previews, but they are not part of the simplified Animate AV V1 product
  promise.

## Legacy Look Reference Matrix

Earlier previews used the eight portrait references as stable identity anchors
across the look library. That historical matrix is useful only when auditing or
regenerating preview assets.

Historical product behavior:

- Selecting a look does not change the narrator voice.
- The voice selector was available only when the user added a message.
- Voice-over options were adult narrator choices, independent from the photo
  subjects.

Use current Create Video tests as the executable source of truth. Any remaining
voice-matrix tests should be treated as legacy coverage until the simplified
card flow removes or rewrites them.

When regenerating any look preview, start from the relevant narrator face and explicitly preserve age, gender presentation, face shape, hairstyle, skin tone, and expression.
