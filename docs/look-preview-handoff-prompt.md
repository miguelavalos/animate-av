# Look Preview Handoff Prompt

Use this prompt to continue the Animate AV look preview generation on another
machine. Replace `<PATH_TO_AVALSYS>` with the local path that contains the
`avalsys` folder.

```text
Goal: Continue generating the remaining Animate AV look preview images with GPT
Image 2, one by one, using the already-defined look-voice matrix.

Workspace:
- Repo path: <PATH_TO_AVALSYS>/public/animate-av
- Voice assets:
  apps/ios/AnimateAV/App/Assets.xcassets/Voice*.imageset/*.png
- Look assets:
  apps/ios/AnimateAV/App/Assets.xcassets/Look*.imageset/*.png

Context:
- `AnimateVideoVoiceProfile.selectorOrder` has 8 voices:
  childGirl, childBoy, teenGirl, teenBoy, adultWoman, adultMan, elderWoman,
  elderMan.
- `AnimateVideoLook.selectorOrder` has 64 looks in 8 families of 8.
- For each look at index `i`, the voice reference is:
  `AnimateVideoVoiceProfile.selectorOrder[i % 8]`.
- `AnimateVideoLook.assetName` points to unique stable assets for the original finished looks. Newly added looks intentionally reuse existing `Look*.imageset` placeholders until final preview generation.
- All referenced `Look*.imageset` assets exist. Placeholder reuse is expected for new looks in this handoff.


Current family structure:
- Popular Looks: Classic Studio, Anime, Cinematic 3D, Comic, Manga, 3D, Watercolor, Paper Cutout
- Cute & Social: Plush Toy, Sticker, Chibi, Mini Avatar, Toy Figure, Soft 3D, Kawaii Pop, Retro Toon
- Comics & Ink: American Comic, European Comic, Hero Comic, Noir Ink, Caricature, Graphic Novel, Sunday Strip, Ink Wash
- Anime & Manga: Shonen Action, Cozy Slice of Life, Magical Fantasy Anime, Cyber Anime, B/W Manga, Shojo Romance, Super Deformed, Anime Watercolor
- Painted & Handmade: Pencil Sketch, Charcoal, Oil Painting, Soft Pastel, Storybook, Ink & Marker, Crayon Kids, Acrylic Poster
- Digital & Game: Pixel Art, Neon Pop, Clean Vector, Low Poly, Voxel World, Synthwave, Glitch Art, Isometric Game
- Fantasy Worlds: Magic Quest, Dark Fantasy, Sci-Fi Space, Steampunk, Pirate Story, Fairytale, Mythic Epic, Yellow Comedy
- Craft & Texture: Stop Motion, Felt Craft, Collage Cutout, Cardboard Theater, Origami, Stained Glass, Embroidered Textile, Vintage Poster

Completed GPT Image 2 previews:
- LookCartoon: VoiceChildGirl
- LookAnime: VoiceChildBoy
- LookCinematic3d: VoiceTeenGirl
- LookWatercolor: VoiceTeenBoy
- LookComic: VoiceAdultWoman
- LookManga: VoiceAdultMan
- LookClay: VoiceElderWoman
- LookPaperCut: VoiceElderMan
- LookPlush: VoiceChildGirl
- LookSticker: VoiceChildBoy
- LookPixel: VoiceTeenGirl

Continue from:
- LookNeon: VoiceTeenBoy
- LookStorybook: VoiceAdultWoman
- LookYellowComedy: VoiceAdultMan
- LookSoft3d: VoiceElderWoman
- LookDarkFantasy: VoiceElderMan
- LookVintagePoster: VoiceChildGirl
- LookPencilSketch: VoiceChildBoy
- LookEditorialCaricature: VoiceTeenGirl
- LookEuroComic: VoiceTeenBoy
- LookAmericanComic: VoiceAdultWoman
- LookStopMotion: VoiceAdultMan
- LookBlackWhiteManga: VoiceElderWoman
- LookToyFigure: VoiceElderMan
- LookChibi: VoiceChildGirl
- LookFlatVector: VoiceChildBoy
- LookPastelDream: VoiceTeenGirl
- LookHeroicComic: VoiceTeenBoy
- LookNoirInk: VoiceAdultWoman
- LookRubberHose: VoiceAdultMan
- LookFantasyQuest: VoiceElderWoman
- LookMiniAvatar: VoiceElderMan

Quality bar:
- Use GPT Image 2 for every remaining preview.
- Use the matching `Voice*.png` as the facial identity reference.
- Preserve identity, age, face shape, core hair silhouette, expression, and
  centered bust framing.
- Clothing may change to reinforce the look. Do not keep the same outfit by
  default.
- Make each look visually radical and immediately recognizable. Avoid subtle
  filters or generic pretty portraits.
- No text, logos, watermarks, extra people, or busy backgrounds.
- Normalize every final PNG to exactly `1024x576`.
- Save each final image to:
  `apps/ios/AnimateAV/App/Assets.xcassets/<LookName>.imageset/<LookName>.png`
- Leave `Contents.json` unchanged unless missing.

After generation:
- Build the app for simulator.
- Run `AnimateLookVoiceMatrixTests`.
- Launch the iOS app in simulator with:
  ANIMATEAV_UI_TESTS=1
  ANIMATEAV_DISABLE_SPLASH=1
  ANIMATEAV_OPEN_TAB=create
  ANIMATEAV_UI_TESTS_ACCOUNT_MODE=signed_in
  ANIMATEAV_CREATE_FIXTURE=story_ready
- Visually verify the family grid and at least one 8-look family detail screen.
- Create a contact sheet for review.
- Commit and push only after visual review and build/test pass.
```
