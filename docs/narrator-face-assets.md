# Narrator Face Assets

Animate AV uses eight narrator faces in the guided voice picker. These portraits are also the identity anchors for generated look previews.

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

## Generation Requirements

- Use a square reference portrait, at least `1024x1024`, exported to `512x512` for the asset catalog.
- Frame as head and shoulders, not full body.
- Keep eyes around 38-42% from the top of the canvas.
- Leave enough padding around hair, ears, chin, and shoulders for a circular avatar crop.
- Use consistent natural daylight, a warm off-white wall or courtyard background, and subtle greenery.
- Avoid side bands, pillarbox margins, watermarks, text, sunglasses, hats, busy backgrounds, and cropped heads.
- The face must still read at `60x60` in the guided voice picker.

## Look Voice Matrix

Use the eight narrator faces as stable identity anchors across the look library. Video looks must be added in complete blocks of eight.

The rule is positional by look family:

- The voice picker has 8 narrator profiles in `AnimateVideoVoiceProfile.selectorOrder`.
- The look picker is organized as 8 families of 8 looks from
  `AnimateVideoLook.families`.
- Within every look family, position 1 maps to voice position 1, position 2 maps to voice position 2, and so on through position 8.
- Selecting a look applies that mapped voice as the default narrator.
- If the user manually changes the voice, later look changes must not override that manual voice choice.

This keeps every page visually balanced while preserving user control. A look preview image is generated once from the narrator face in the same matrix position, then the app keeps the same look-to-voice link through code.

The current matrix is encoded in
`apps/ios/AnimateAV/AnimateDomain/Models/AnimateVideoCreationModels.swift`.
Use `AnimateLookVoiceMatrixTests` as the executable source of truth for the
64-look family count, the 8-position voice mapping, unique assets, and manual
voice override behavior.

When regenerating any look preview, start from the relevant narrator face and explicitly preserve age, gender presentation, face shape, hairstyle, skin tone, and expression.
