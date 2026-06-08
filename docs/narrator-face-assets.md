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

## 32-Look Matrix

Use the eight narrator faces as stable identity anchors across the look library. The target structure is:

- 8 narrator faces.
- 4 generated looks per narrator face.
- 32 total look previews.

Each group of four look previews should preserve the same face identity while varying only the visual style. This keeps the library diverse without making every generated look feel like a different narrator.

Recommended grouping:

| Narrator | Looks |
| --- | --- |
| Child girl | Cartoon, sticker, pastel dream, storybook |
| Child boy | Soft 3D, toy figure, clay, mini avatar |
| Teen girl | Anime, chibi, manga, black-white manga |
| Teen boy | Pixel, neon, heroic comic, fantasy quest |
| Adult woman | Watercolor, flat vector, paper cut, vintage poster |
| Adult man | Cinematic 3D, stop motion, plush, yellow comedy |
| Older woman | Pencil sketch, editorial caricature, euro comic, noir ink |
| Older man | Comic, american comic, dark fantasy, rubber hose |

When regenerating any look preview, start from the relevant narrator face and explicitly preserve age, gender presentation, face shape, hairstyle, skin tone, and expression.
