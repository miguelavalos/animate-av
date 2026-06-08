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
- `AnimateVideoLook.selectorOrder` has 32 looks in 4 pages of 8.
- For each look at index `i`, the voice reference is:
  `AnimateVideoVoiceProfile.selectorOrder[i % 8]`.
- `AnimateVideoLook.assetName` now points to a unique `Look<PascalCase>.imageset`
  for every look.
- All `Look*.imageset` assets exist. Some are final GPT Image 2 previews; the
  rest are placeholders and must be replaced.

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
- Visually verify all 4 look pages.
- Create a contact sheet for review.
- Commit and push only after visual review and build/test pass.
```
