# Look Family UI Contract

Status: implemented and active for the simplified Create Video flow.

This document is the public-safe contract for reviewing the video look picker,
look preview assets, and guided setup relationship. It is no longer an
implementation plan.

## Current Contract

- The video look model lives in
  `apps/ios/AnimateAV/AnimateDomain/Models/AnimateVideoCreationModels.swift`.
- `AnimateVideoLook.families` contains exactly 8 families with exactly 8 looks
  each.
- `AnimateVideoLook.selectorOrder` is the flattened family order and currently
  contains 64 unique looks.
- The look picker shows family navigation first, then the selected family's 8
  looks.
- Every final look has a unique `Look*.imageset` preview asset.
- Look selection is independent from Animation and optional written
  Message/Dedication.
- Animation is its own guided Create Video step after Look and before
  Message/Dedication.
- Animate AV V1 is not a voice product. Do not add visible narrator, voice,
  tone, generated-audio, or in-app audio controls to the look flow.

## Guided Create Video Flow

The visible guided setup order is:

```text
Photo and framing -> Look -> Animation -> optional written Message/Dedication
```

Credit review becomes visible only after:

- a renderable local source photo exists;
- a look has been selected;
- the Animation step has been completed;
- the optional Message/Dedication step has been completed or skipped.

The setup summary must show Photo/framing, Look, Animation, and Message in that
order.

Any compact/basic guide shown outside the sheet must mirror the same setup
state. It can point the user to the next required action, but it must not merge
Look and Animation or add a separate review step before credit confirmation.

## Families And Looks

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

## Maintenance Rules

- Keep raw enum values stable for existing looks because saved jobs and payloads
  may reference them.
- Future visible copy changes must update `en`, `es`, `ca`, `fr`, and `de`
  together and preserve placeholder parity.
- Do not add placeholder preview reuse for final looks. A new final look needs a
  unique `Look*.imageset`.
- If a look is renamed publicly but keeps the same enum case, update only
  localized display copy unless a backend/raw-value migration is explicitly
  planned.
- Keep image-generation look ordering in sync with video look families when
  user-facing names change.
- Do not reintroduce flat endless pagination for the video look picker.

## Verification

After any look picker, look model, preview asset, or visible look copy change:

- run `AnimateLookFamilyMatrixTests`;
- build the iOS app for Simulator;
- inspect the family grid and at least two complete family detail screens;
- verify the guided Create Video summary still shows Photo/framing, Look,
  Animation, and Message in order;
- check that no visible voice/audio/tone controls appear in Create Video.
