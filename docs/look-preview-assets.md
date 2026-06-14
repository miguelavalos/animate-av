# Look Preview Assets

Animate AV look previews live in `apps/ios/AnimateAV/App/Assets.xcassets` as
`Look<PascalCaseLook>.imageset/Look<PascalCaseLook>.png`.

Each preview is a stable `1024x576` image because the look selector renders
`Image(look.assetName)` in a fixed 16:9-style tile with `scaledToFill`.

The source identity for existing look previews follows the historical family
portrait matrix:

```text
portrait = legacyPortraitOrder[indexInFamily]
```

where `indexInFamily` is the look position inside its 8-look family. This is
asset provenance only. Runtime look selection does not change the voice-over
narrator.

The first family grid uses a curated set of 8 `heroAssetName` previews. Keep
that screen visually balanced by age/gender position where the available assets
allow it: child girl, child boy, teen girl, teen boy, adult woman, adult man,
older woman, older man. Do not point every family hero at position 0; that
makes the first screen repeat the same source identity.

Final look previews have been completed for all 64 looks. Every
`AnimateVideoLook.assetName` points to a stable, unique
`Look<PascalCaseLook>.imageset` entry, and placeholder reuse is no longer
expected or allowed.

Current asset state:

- `AnimateVideoLook` contains 64 looks organized into 8 families of 8.
- All 64 previews exist as `1024x576` PNG files in matching `Look*.imageset`
  folders.
- The asset matrix is fully unique: each look has its own `assetName`.
- `AnimateLookVoiceMatrixTests` verifies family count, family size, adult
  narrator selector count, unique look preview assets, asset existence, and that
  look changes do not alter narrator voice.
