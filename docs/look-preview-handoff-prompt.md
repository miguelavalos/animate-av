# Look Preview Maintenance Prompt

The Animate AV look preview handoff is complete. Use this file only when a
future agent needs to review or replace preview images.

Current state:

- Repo path: `<PATH_TO_AVALSYS>/public/animate-av`
- Look assets:
  `apps/ios/AnimateAV/App/Assets.xcassets/Look*.imageset/*.png`
- `AnimateVideoLook.selectorOrder` has 64 looks in 8 families of 8.
- Every final preview is a unique `1024x576` PNG.
- Runtime look selection does not imply narrator, voice, tone, or generated
  audio behavior.

Family structure:

- Popular Looks: Cartoon Adventure, Anime, Cinematic 3D, Comic Book, Manga,
  Clay Animation, Watercolor Storybook, Paper Cutout
- Cute & Social: Plush Toy, Sticker Pack, Chibi, Mini Avatar, Toy Figure,
  Soft 3D, Kawaii Pop, Bubble Cartoon
- Comics & Ink: American Comic, European Comic, Hero Comic, Noir Ink,
  Editorial Caricature, Graphic Novel, Sunday Strip, Ink Wash
- Anime & Manga: Shonen Action, Cozy Slice of Life, Magical Fantasy Anime,
  Cyber Anime, Black & White Manga, Shojo Romance, Super Deformed,
  Anime Watercolor
- Painted & Handmade: Pencil Sketch, Charcoal, Oil Painting, Pastel Dream,
  Gouache Storybook, Ink & Marker, Crayon Kids, Acrylic Poster
- Digital & Game: Pixel Art, Neon Pop, Low Poly, Voxel World, Synthwave,
  Glitch Art, Isometric Game, HD-2D Adventure
- Fantasy Worlds: Fantasy Quest, Dark Fantasy, Sci-Fi Space, Steampunk, Pirate
  Story, Fairytale, Mythic Epic, Cozy Magic
- Craft & Texture: Stop Motion, Felt Craft, Collage Cutout, Cardboard Theater,
  Origami, Stained Glass, Embroidered Textile, Vintage Poster

Maintenance rules:

- Keep every final PNG normalized to exactly `1024x576`.
- Keep `AnimateVideoLook.assetName` unique across all 64 looks.
- Do not introduce shared placeholders for final looks.
- Keep family hero assets curated for the first-screen visual progression
  instead of repeating one source identity.
- If replacing a preview, preserve the same imageset and filename unless there
  is a deliberate model rename.
- Do not include text, logos, watermarks, extra people, or busy backgrounds in
  look previews.

Verification checklist after any future preview change:

- Run `AnimateLookFamilyMatrixTests`.
- Build the iOS app for Simulator.
- Launch the app and visually check the look selector.
- Review the family grid and at least two complete 8-look family screens.
- Regenerate `tmp/look-preview-contact-sheet.png` for local visual review when
  changing assets.
