# Look Family UI Implementation Plan

This plan covers the code and UX work needed before generating any new look
preview images. The image-generation pass should be a separate follow-up after
this plan builds, tests, and lands.

## Goal

Replace the flat paginated look selector with a style-family flow:

1. Show a main grid/list of look families.
2. Let the user enter one family.
3. Show exactly 8 looks in that family.
4. Keep the voice matrix stable by mapping each family to the same 8 voice
   positions.
5. Use temporary placeholder assets for new looks until the image-generation
   pass.

This preserves the "8 looks per voice block" rule while making the library
scale beyond 32 looks without endless pagination.

## Current Audit

- Video look data is centralized in
  `apps/ios/AnimateAV/AnimateDomain/Models/AnimateVideoCreationModels.swift`.
  `AnimateVideoLook.selectorOrder` currently contains 32 looks, arranged as 4
  flat pages of 8.
- `AnimateVideoLook.defaultVoiceProfile` depends on selector index modulo
  `AnimateVideoVoiceProfile.selectorOrder.count`.
- The guided video flow uses pagination in
  `apps/ios/AnimateAV/Features/Create/AnimateCreateWorkflowContent.swift`:
  `lookPageIndex`, `looksPerPage`, `lookPageCount`, and `visibleLooks`.
- The setup look chooser in the same file renders the full flat
  `AnimateVideoLook.selectorOrder` grid without family grouping.
- Image generation has a separate enum,
  `AnimateCreateImageLook`, in
  `apps/ios/AnimateAV/Features/Create/AnimateCreateImagesWorkspace.swift`.
  It mirrors the 32 look cases but already reuses a smaller set of preview
  assets for several looks.
- `AnimateCreateImagesLookSheet` also uses flat pagination with 8 looks per
  page.
- `AnimateLookVoiceMatrixTests` currently verifies the 32-look selector count,
  modulo voice mapping, unique video preview assets, and voice override
  behavior.
- There are currently 32 unique `Look*.imageset` preview assets for video
  looks.
- Look titles/subtitles are localized in the app's `.lproj/Localizable.strings`
  files. New family titles/subtitles and new looks need localization keys.

## Product Decision

Use family navigation for the video look selector first, because that is where
look + voice pairing matters most. Keep image-generation look selection in
scope only if we want the whole app to feel consistent in the same commit.

Recommended scope for the first implementation commit:

- Migrate the video look selection UX to families.
- Add shared family data in the domain model.
- Update the full setup chooser and the guided flow sheet.
- Add all 64 planned looks to the model with placeholder assets for new looks.
- Update tests for the new family contract.
- Optionally migrate the image-generation sheet if the same family structure can
  be reused without widening the commit too much.

## Proposed Families

Each family has 8 looks. The first family is the default entry point and should
remain the most broadly recognizable set for Europe and America.

1. Popular Looks
   Fast, recognizable styles for most videos.
   - Cartoon Adventure
   - Anime
   - Cinematic 3D
   - Comic Book
   - Manga
   - Clay Animation
   - Watercolor Storybook
   - Paper Cutout

2. Cute & Social
   Soft, playful looks for friendly clips.
   - Plush Toy
   - Sticker Pack
   - Chibi
   - Mini Avatar
   - Toy Figure
   - Soft 3D
   - Kawaii Pop
   - Bubble Cartoon

3. Comics & Ink
   Bold lines, panels, posters, and graphic art.
   - American Comic
   - European Comic
   - Hero Comic
   - Noir Ink
   - Editorial Caricature
   - Graphic Novel
   - Sunday Strip
   - Ink Wash

4. Anime & Manga
   Expressive illustrated looks with dramatic motion.
   - Shonen Action
   - Cozy Slice of Life
   - Magical Fantasy Anime
   - Cyber Anime
   - Black & White Manga
   - Shojo Romance
   - Super Deformed
   - Anime Watercolor

5. Painted & Handmade
   Traditional art textures and illustrated scenes.
   - Pencil Sketch
   - Charcoal
   - Oil Painting
   - Pastel Dream
   - Gouache Storybook
   - Ink & Marker
   - Crayon Kids
   - Acrylic Poster

6. Digital & Game
   Pixel, voxel, neon, and modern screen styles.
   - Pixel Art
   - Neon Pop
   - Low Poly
   - Voxel World
   - Synthwave
   - Glitch Art
   - Isometric Game
   - HD-2D Adventure

7. Fantasy Worlds
   Genre scenes with cinematic character treatment.
   - Fantasy Quest
   - Dark Fantasy
   - Sci-Fi Space
   - Steampunk
   - Pirate Story
   - Fairytale
   - Mythic Epic
   - Cozy Magic

8. Craft & Texture
   Paper, felt, collage, and tactile materials.
   - Stop Motion
   - Felt Craft
   - Collage Cutout
   - Cardboard Theater
   - Origami
   - Stained Glass
   - Embroidered Textile
   - Vintage Poster

## Implementation Steps

1. Add a family model.
   - Add `AnimateVideoLookFamily: Identifiable`.
   - Include `id`, `title`, `subtitle`, `looks`, and possibly `heroAssetName`.
   - Add `AnimateVideoLook.families`.
   - Derive `AnimateVideoLook.selectorOrder` from flattened families so existing
     API payloads and selection logic continue to work.

2. Expand `AnimateVideoLook`.
   - Add the new look enum cases.
   - Keep existing raw values stable for current looks.
   - Use brand-safe generic names only; no studio, franchise, or character
     names.
   - Add `title`, `subtitle`, `assetName`, and `systemImage` switches for every
     new case.

3. Assign placeholder assets.
   - Keep current unique assets for the existing 32 looks.
   - Point every new look to a known temporary asset, for example
     `LookCartoon`, `LookComic`, `LookAnime`, or a single new
     `LookPlaceholder`.
   - If `AnimateLookVoiceMatrixTests` should keep requiring unique assets only
     for finished previews, split the test into "all assets exist" and
     "existing finished looks keep stable unique assets."

4. Add localization keys.
   - Add family title/subtitle keys.
   - Add new look title/subtitle keys.
   - Update at least all current supported `.lproj/Localizable.strings` files in
     the same commit so build-time string lookup stays clean.

5. Replace guided look pagination.
   - Remove `lookPageIndex`, `lookPageCount`, and `visibleLooks` from
     `AnimateCreateGuidedFlowCard`.
   - Add a selected family state, defaulting to the first family or the family
     containing the selected look.
   - In the look sheet, show family tiles first.
   - On family tap, show that family's 8 look tiles with title/subtitle header
     and a back affordance.
   - Keep `selectLook(look)` behavior unchanged so default voice assignment
     remains owned by the view model.

6. Replace setup chooser flat grid.
   - Update `AnimateCreateLookChooserView` to show family tiles first.
   - Entering a family shows the same 8-look grid and selected state.
   - If a selected look exists, initialize the chooser inside its family or mark
     the family tile clearly.

7. Decide image-generation scope.
   - Preferred follow-up within the same commit if time allows: make
     `AnimateCreateImageLook` reuse the same family concept or derive from video
     looks to remove duplicated ordering.
   - Conservative option: leave image generation unchanged for this commit and
     document it as a separate migration. This reduces risk because image
     generation supports multi-select and has different asset reuse rules.

8. Update tests.
   - Assert there are 8 families.
   - Assert every family has exactly 8 looks.
   - Assert the flattened selector count is 64.
   - Assert all looks are unique across families.
   - Assert every family maps positions 0...7 to the 8 voice profiles.
   - Assert `defaultVoiceProfile` still uses family/block position.
   - Assert all `assetName` values resolve to an asset catalog entry, allowing
     placeholders for new looks.
   - Keep tests for manual voice override unchanged.

9. Update docs.
   - Update `docs/look-preview-assets.md` to describe family-based blocks.
   - Update `docs/look-preview-handoff-prompt.md` only after the code structure
     is final, so the later image-generation pass has the correct matrix.
   - Keep image generation instructions explicitly out of this first commit
     except for placeholder policy.

10. Verify.
    - Run the focused look matrix tests.
    - Run the relevant create workflow tests.
    - Build on an iOS Simulator that is not iPhone 17.
    - Manually inspect the look chooser and guided look sheet.
    - Capture screenshots for the family grid and one family detail screen.

## Acceptance Criteria Before Image Generation

- The app builds.
- The new family UI is usable without missing assets.
- No selector has endless look pagination.
- Every family contains exactly 8 looks.
- The voice-link matrix remains deterministic and test-covered.
- Existing selected looks and API raw values continue to work.
- New looks use placeholders clearly enough for internal review.
- The commit contains code, localization, docs, tests, and placeholder asset
  wiring only; no generated final preview images.

## Suggested First Commit

Commit title:

```text
Restructure look picker into style families
```

Do not include final generated look previews in this commit. The next commit
should be dedicated to replacing placeholders with generated assets and visual
QA.
