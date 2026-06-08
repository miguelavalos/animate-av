# Look Preview Assets

Animate AV look previews live in `apps/ios/AnimateAV/App/Assets.xcassets` as
`Look<PascalCaseLook>.imageset/Look<PascalCaseLook>.png`.

Each preview is a stable `1024x576` image because the look selector renders
`Image(look.assetName)` in a fixed 16:9-style tile with `scaledToFill`.

The source identity for every look follows the look-voice matrix:

```text
voice = AnimateVideoVoiceProfile.selectorOrder[index % 8]
```

where `index` is the look position in `AnimateVideoLook.selectorOrder`. The
first page of 8 looks uses the 8 voice identities in voice selector order, and
each later page repeats that same order.

Final look previews are generated one by one with GPT Image 2 using the matching
`Voice*.imageset` PNG as the facial identity reference. The prompt must preserve
identity, age, facial traits, expression, and bust framing while pushing the look
style strongly enough to be immediately recognizable. Clothing may vary when it
helps the selected look read clearly.

Generated images should be copied into the matching imageset and normalized to
`1024x576`.

Current handoff state:

- GPT Image 2 previews completed: `LookCartoon`, `LookAnime`,
  `LookCinematic3d`, `LookWatercolor`, `LookComic`, `LookManga`, `LookClay`,
  `LookPaperCut`, `LookPlush`, `LookSticker`, `LookPixel`.
- Remaining `Look*.imageset` assets are present as stable placeholders and must
  be replaced with GPT Image 2 previews before final acceptance.
