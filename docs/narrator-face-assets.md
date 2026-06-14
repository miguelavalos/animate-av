# Narrator Face Assets

Animate AV currently uses adult voice-over narrators only. The voice-over is an
off-screen message track; it is not a character voice for people in the photo.

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

## Current Runtime Voices

The shipped selector uses:

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
- Runtime narrator portraits must still read at `60x60` in the voice-over
  picker.

## Legacy Look Reference Matrix

Earlier previews used the eight portrait references as stable identity anchors
across the look library. That historical matrix is useful only when auditing or
regenerating preview assets.

Current product behavior:

- Selecting a look does not change the narrator voice.
- The voice selector is available only when the user adds a message.
- Voice-over options are adult narrator choices, independent from the photo
  subjects.

Use `AnimateLookVoiceMatrixTests` as the executable source of truth for the
64-look family count, two adult narrator choices, unique assets, and the rule
that look selection does not change the selected narrator.

When regenerating any look preview, start from the relevant narrator face and explicitly preserve age, gender presentation, face shape, hairstyle, skin tone, and expression.
