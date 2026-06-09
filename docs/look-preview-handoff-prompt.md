# Look Preview Handoff Prompt

The Animate AV look preview handoff is complete.

Current state:

- Repo path: `<PATH_TO_AVALSYS>/public/animate-av`
- Voice assets:
  `apps/ios/AnimateAV/App/Assets.xcassets/Voice*.imageset/*.png`
- Look assets:
  `apps/ios/AnimateAV/App/Assets.xcassets/Look*.imageset/*.png`
- `AnimateVideoVoiceProfile.selectorOrder` has 8 voices:
  `childGirl`, `childBoy`, `teenGirl`, `teenBoy`, `adultWoman`, `adultMan`,
  `elderWoman`, `elderMan`.
- `AnimateVideoLook.selectorOrder` has 64 looks in 8 families of 8.
- For each look position inside a family, the voice reference is:

```text
voice = AnimateVideoVoiceProfile.selectorOrder[indexInFamily]
```

All 64 final previews now exist. Each look points to a unique stable
`Look<PascalCaseLook>.imageset` asset, and no look preview should share a
placeholder asset.

Family structure:

- Popular Looks: Classic Studio, Anime, Cinematic 3D, Comic, Manga, 3D,
  Watercolor, Paper Cutout
- Cute & Social: Plush Toy, Sticker, Chibi, Mini Avatar, Toy Figure, Soft 3D,
  Kawaii Pop, Retro Toon
- Comics & Ink: American Comic, European Comic, Hero Comic, Noir Ink,
  Caricature, Graphic Novel, Sunday Strip, Ink Wash
- Anime & Manga: Shonen Action, Cozy Slice of Life, Magical Fantasy Anime,
  Cyber Anime, B/W Manga, Shojo Romance, Super Deformed, Anime Watercolor
- Painted & Handmade: Pencil Sketch, Charcoal, Oil Painting, Soft Pastel,
  Storybook, Ink & Marker, Crayon Kids, Acrylic Poster
- Digital & Game: Pixel Art, Neon Pop, Clean Vector, Low Poly, Voxel World,
  Synthwave, Glitch Art, Isometric Game
- Fantasy Worlds: Magic Quest, Dark Fantasy, Sci-Fi Space, Steampunk, Pirate
  Story, Fairytale, Mythic Epic, Yellow Comedy
- Craft & Texture: Stop Motion, Felt Craft, Collage Cutout, Cardboard Theater,
  Origami, Stained Glass, Embroidered Textile, Vintage Poster

Maintenance rules:

- Keep every final PNG normalized to exactly `1024x576`.
- Keep `AnimateVideoLook.assetName` unique across all 64 looks.
- Do not introduce shared placeholders for final looks.
- If replacing a preview, preserve the same imageset and filename unless there
  is a deliberate model rename.
- No text, logos, watermarks, extra people, or busy backgrounds in look
  previews.

Verification checklist after any future preview change:

- Run `AnimateLookVoiceMatrixTests`.
- Build the iOS app for a simulator.
- Launch the app with create-tab UI test environment flags when visually
  checking the selector.
- Review the family grid and at least two complete 8-look family screens.
- Regenerate `tmp/look-preview-contact-sheet.png` for local visual review.
