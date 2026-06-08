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

- Use a square source image, at least `1024x1024`, exported to `512x512` for the asset catalog.
- Frame as head and shoulders, not full body.
- Keep eyes around 38-42% from the top of the canvas.
- Leave enough padding around hair, ears, chin, and shoulders for a circular avatar crop.
- Use consistent natural daylight, a warm off-white wall or courtyard background, and subtle greenery.
- Avoid side bands, pillarbox margins, watermarks, text, sunglasses, hats, busy backgrounds, and cropped heads.
- The face must still read at `60x60` in the guided voice picker.

## Look Voice Matrix

Use the eight narrator faces as stable identity anchors across the look library. Video looks must be added in complete blocks of eight.

The rule is positional:

- The voice picker has 8 narrator profiles in `AnimateVideoVoiceProfile.selectorOrder`.
- The look picker is paged in blocks of 8 from `AnimateVideoLook.selectorOrder`.
- Within every look page, position 1 maps to voice position 1, position 2 maps to voice position 2, and so on through position 8.
- Selecting a look applies that mapped voice as the default narrator.
- If the user manually changes the voice, later look changes must not override that manual voice choice.

This keeps every page visually balanced while preserving user control. A look preview image is generated once from the narrator face in the same matrix position, then the app keeps the same look-to-voice link through code.

The current matrix is:

| Page | Position | Voice profile | Current look |
| --- | --- | --- | --- |
| 1 | 1 | Child girl | Cartoon |
| 1 | 2 | Child boy | Anime |
| 1 | 3 | Teen girl | Cinematic 3D |
| 1 | 4 | Teen boy | Watercolor |
| 1 | 5 | Adult woman | Comic |
| 1 | 6 | Adult man | Manga |
| 1 | 7 | Older woman | 3D |
| 1 | 8 | Older man | Paper cut |
| 2 | 1 | Child girl | Plush |
| 2 | 2 | Child boy | Sticker |
| 2 | 3 | Teen girl | Pixel |
| 2 | 4 | Teen boy | Neon |
| 2 | 5 | Adult woman | Storybook |
| 2 | 6 | Adult man | Yellow comedy |
| 2 | 7 | Older woman | Soft 3D |
| 2 | 8 | Older man | Dark fantasy |
| 3 | 1 | Child girl | Vintage poster |
| 3 | 2 | Child boy | Pencil sketch |
| 3 | 3 | Teen girl | Editorial caricature |
| 3 | 4 | Teen boy | Euro comic |
| 3 | 5 | Adult woman | American comic |
| 3 | 6 | Adult man | Stop motion |
| 3 | 7 | Older woman | Black-white manga |
| 3 | 8 | Older man | Toy figure |
| 4 | 1 | Child girl | Chibi |
| 4 | 2 | Child boy | Flat vector |
| 4 | 3 | Teen girl | Pastel dream |
| 4 | 4 | Teen boy | Heroic comic |
| 4 | 5 | Adult woman | Noir ink |
| 4 | 6 | Adult man | Rubber hose |
| 4 | 7 | Older woman | Fantasy quest |
| 4 | 8 | Older man | Mini avatar |

When regenerating any look preview, start from the relevant narrator face and explicitly preserve age, gender presentation, face shape, hairstyle, skin tone, and expression.
