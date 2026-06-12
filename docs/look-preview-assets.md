# Look Preview Assets

Animate AV look previews live in `apps/ios/AnimateAV/App/Assets.xcassets` as
`Look<PascalCaseLook>.imageset/Look<PascalCaseLook>.png`.

Each preview is a stable `1024x576` image because the look selector renders
`Image(look.assetName)` in a fixed 16:9-style tile with `scaledToFill`.

The source identity for every look follows the family look-voice matrix:

```text
voice = AnimateVideoVoiceProfile.selectorOrder[indexInFamily]
```

where `indexInFamily` is the look position inside its 8-look family. The
selector is organized as 8 families of 8 looks. Each family repeats the same 8
voice identities in voice selector order.

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
- `AnimateLookVoiceMatrixTests` verifies family count, family size, selector
  count, deterministic voice assignment, unique look preview assets, asset
  existence, and manual voice override behavior.
