# Look Family UI Implementation Plan

Status: implemented and aligned with the simplified Create Video flow.

This document is now the current contract for reviewing the look picker. The
family UI and 64-look model exist; the remaining work is product polish,
English naming review, and visual QA before production smoke.

## Goal

Maintain the style-family look selector:

1. Show a main grid/list of look families.
2. Let the user enter one family.
3. Show exactly 8 looks in that family.
4. Keep one unique final preview asset per look.
5. Keep look selection independent from voice-over selection.

The voice-over selector is no longer tied to look position. It appears only when
the user adds a message and offers adult narrator choices.

## Current Audit

- Video look data is centralized in
  `apps/ios/AnimateAV/AnimateDomain/Models/AnimateVideoCreationModels.swift`.
  `AnimateVideoLook.families` currently contains 8 families with 8 looks each.
- The simplified create flow uses family navigation for look selection and keeps
  voice-over selection independent from the chosen look.
- Image generation has a separate enum,
  `AnimateCreateImageLook`, in
  `apps/ios/AnimateAV/Features/Create/AnimateCreateImagesWorkspace.swift`.
  It mirrors the video look families.
- `AnimateLookVoiceMatrixTests` verifies family size, adult narrator selector
  count, unique preview assets, asset existence, and that look changes do not
  alter narrator voice.
- There are currently 64 unique `Look*.imageset` preview assets for video
  looks.
- Look and family titles/subtitles are localized for the shipped runtime
  locales. Future copy changes must update `en`, `es`, `ca`, `fr`, and `de`
  together and preserve placeholder parity.

## Product Decision

Use family navigation for the video look selector because look is the strongest
user-facing control. Voice-over is a separate optional message control.

Current review scope:

- Review whether the first family should remain `Popular Looks` or become a
  more product-specific entry such as recommended starter looks.
- Review each family title/subtitle and each look title/subtitle across the
  shipped locales when changing product copy.
- Review all 64 look images in the app, not only the asset catalog.
- Keep exactly 8 looks per family and one unique preview asset per look.
- Keep narrator selection independent from look selection.

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
