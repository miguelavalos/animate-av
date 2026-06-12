# Animate AV Canonical Asset Handoff

Status: required before adding or changing final App Store icon, launch logo,
splash, onboarding, AV monogram usage, Avi artwork, or framed screenshot assets
in this public repo.

Do not use this document to approve generated, approximate, or exploratory
artwork. It is a handoff record for already-approved canonical assets.

## Current Status

The initial Animate AV iOS branding package is approved for runtime use in the
public iOS app. Future replacements must update this handoff with the new
package and checksums.

Animate AV follows the shared Apps AV first-run branding pattern:

```text
native launch logo + icon -> product splash with Avi -> onboarding
```

Do not import exploratory Animate AV logo, mark, concept, or icon files from
private brand working folders as final App Store assets without updating this
handoff.

## Asset Package

- Package name: Animate AV iOS initial branding package
- Date: 2026-06-07
- Owner: AVALSYS
- Reviewer: AVALSYS product owner
- Approval reference: private brand-system Animate AV canonical handoff
- Source location: private AVALSYS suite brand-system canonical exports
- Export location: `apps/ios/AnimateAV/App`
- Intended release: Animate AV iOS v1

## Included Assets

```text
Asset: Native launch logo
Repo path: apps/ios/AnimateAV/App/AnimateLaunchLogo.png
Type: launch logo
Export size: 884 x 300
Format: PNG
Checksum: sha256 28037193625dd71eb7b2182828a41ca8d790ecf8d57e7dedf63f5d6b914d0284
Purpose: native launch screen logo plus icon
Approved: yes

Asset: Full transparent Animate AV logo
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AnimateAVLogo.imageset/animate-av-logo-transparent.png
Type: full logo
Export size: 1638 x 320
Format: PNG
Checksum: sha256 f9b0d53651949a23544d15e5b980e64d2b2bde3db7955598e9846b1e8444fe58
Purpose: splash and large branding surfaces
Approved: yes

Asset: Animate AV header wordmark
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AnimateHeaderWordmark.imageset/animate-header-wordmark.png
Type: wordmark
Export size: 1106 x 212
Format: PNG
Checksum: sha256 902ac3510f7f605eaedda83a4d7887d4f9b0a5782c2199bdf2cd22e350c0a27b
Purpose: compact iOS header/onboarding brand surface
Approved: yes

Asset: Animate AV app icon source
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-1024.png
Type: app icon
Export size: 1024 x 1024
Format: PNG
Checksum: sha256 2b9cbec97a23e78fcf8d60aa96f6da07db2af524842a09cd763b33f4ac8e8e39
Purpose: App Store and iOS app icon source
Approved: yes

Asset: Animate AV splash hero
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AnimateSplashHero.imageset/animate-splash-hero@1x.png
Type: splash artwork / Avi artwork
Export size: 330 x 386
Format: PNG
Checksum: sha256 78b6d65c5c2b8588620579e107ef89bcfa2fe91113b5fd283bbabb8188a586f2
Purpose: product splash with Avi as assistant
Approved: yes

Asset: Animate AV onboarding hero
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AnimateOnboardingHero.imageset/animate-onboarding-hero@1x.png
Type: onboarding artwork
Export size: 941 x 1672
Format: PNG
Checksum: sha256 acb377b76883e5301ff82703cb68684eaa54d61497d7bcc835d6e66faf38aef0
Purpose: onboarding product concept without duplicate Avi
Approved: yes
```

## Approved Tracked Runtime Derivatives

The following tracked runtime files are approved as part of the same package.
They are derived app icon renditions, light/dark wordmark variants, launch
aliases, shared Avi runtime exports, and product-specific look/mood/style
thumbnails reviewed in the shipped iOS UI.

```text
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AnimateHeaderWordmark.imageset/animate-header-wordmark-dark.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AnimateLaunchIcon.imageset/animate-launch-icon.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-20@2x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-20@3x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-29@2x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-29@3x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-40@2x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-40@3x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-60@2x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AppIcon.appiconset/Icon-60@3x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AviFooterIcon.imageset/avi-footer-icon@1x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AviFooterIcon.imageset/avi-footer-icon@2x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AviFooterIcon.imageset/avi-footer-icon@3x.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AviFullBody.imageset/avi-full-body.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AviLoginSheetPeek.imageset/avi-v2-login-sheet-peek.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/AviOnboardingCTA.imageset/avi-v2-onboarding-cta.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookAcrylicPoster.imageset/LookAcrylicPoster.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookAmericanComic.imageset/LookAmericanComic.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookAnime.imageset/LookAnime.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookAnimeWatercolor.imageset/LookAnimeWatercolor.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookBlackWhiteManga.imageset/LookBlackWhiteManga.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCardboardTheater.imageset/LookCardboardTheater.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCartoon.imageset/LookCartoon.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCharcoal.imageset/LookCharcoal.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookChibi.imageset/LookChibi.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCinematic3d.imageset/LookCinematic3d.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookClay.imageset/LookClay.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCollageCutout.imageset/LookCollageCutout.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookComic.imageset/LookComic.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCozySliceOfLife.imageset/LookCozySliceOfLife.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCrayonKids.imageset/LookCrayonKids.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookCyberAnime.imageset/LookCyberAnime.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookDarkFantasy.imageset/LookDarkFantasy.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookEditorialCaricature.imageset/LookEditorialCaricature.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookEmbroideredTextile.imageset/LookEmbroideredTextile.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookEuroComic.imageset/LookEuroComic.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookFairytale.imageset/LookFairytale.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookFantasyQuest.imageset/LookFantasyQuest.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookFeltCraft.imageset/LookFeltCraft.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookFlatVector.imageset/LookFlatVector.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookGlitchArt.imageset/LookGlitchArt.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookGraphicNovel.imageset/LookGraphicNovel.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookHeroicComic.imageset/LookHeroicComic.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookInkMarker.imageset/LookInkMarker.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookInkWash.imageset/LookInkWash.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookIsometricGame.imageset/LookIsometricGame.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookKawaiiPop.imageset/LookKawaiiPop.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookLowPoly.imageset/LookLowPoly.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookMagicalFantasyAnime.imageset/LookMagicalFantasyAnime.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookManga.imageset/LookManga.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookMiniAvatar.imageset/LookMiniAvatar.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookMythicEpic.imageset/LookMythicEpic.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookNeon.imageset/LookNeon.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookNoirInk.imageset/LookNoirInk.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookOilPainting.imageset/LookOilPainting.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookOrigami.imageset/LookOrigami.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookPaperCut.imageset/LookPaperCut.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookPastelDream.imageset/LookPastelDream.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookPencilSketch.imageset/LookPencilSketch.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookPirateStory.imageset/LookPirateStory.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookPixel.imageset/LookPixel.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookPlush.imageset/LookPlush.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookRubberHose.imageset/LookRubberHose.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSciFiSpace.imageset/LookSciFiSpace.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookShojoRomance.imageset/LookShojoRomance.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookShonenAction.imageset/LookShonenAction.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSoft3d.imageset/LookSoft3d.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookStainedGlass.imageset/LookStainedGlass.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSteampunk.imageset/LookSteampunk.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSticker.imageset/LookSticker.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookStopMotion.imageset/LookStopMotion.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookStorybook.imageset/LookStorybook.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSundayStrip.imageset/LookSundayStrip.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSuperDeformed.imageset/LookSuperDeformed.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookSynthwave.imageset/LookSynthwave.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookToyFigure.imageset/LookToyFigure.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookVintagePoster.imageset/LookVintagePoster.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookVoxelWorld.imageset/LookVoxelWorld.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookWatercolor.imageset/LookWatercolor.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/LookYellowComedy.imageset/LookYellowComedy.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/MoodCalm.imageset/MoodCalm.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/MoodCinematic.imageset/MoodCinematic.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/MoodFun.imageset/MoodFun.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/MoodUpbeat.imageset/MoodUpbeat.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/MoodWarm.imageset/MoodWarm.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleBirthday.imageset/StyleBirthday.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleCelebration.imageset/StyleCelebration.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleCustom.imageset/StyleCustom.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleEventRecap.imageset/StyleEventRecap.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleFamilyCartoon.imageset/StyleFamilyCartoon.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleFavoritePeople.imageset/StyleFavoritePeople.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleMilestone.imageset/StyleMilestone.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleSoftRoast.imageset/StyleSoftRoast.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/StyleTravel.imageset/StyleTravel.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceAdultMan.imageset/VoiceAdultMan.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceAdultWoman.imageset/VoiceAdultWoman.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceChildBoy.imageset/VoiceChildBoy.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceChildGirl.imageset/VoiceChildGirl.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceElderMan.imageset/VoiceElderMan.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceElderWoman.imageset/VoiceElderWoman.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceTeenBoy.imageset/VoiceTeenBoy.png
Repo path: apps/ios/AnimateAV/App/Assets.xcassets/VoiceTeenGirl.imageset/VoiceTeenGirl.png
```

## Required Rules

- [x] App icon source is approved for Animate AV.
- [x] Native launch logo source is approved for Animate AV.
- [x] Splash artwork source is approved for Animate AV.
- [x] Onboarding artwork source is approved for Animate AV.
- [x] Splash artwork shows Avi as a useful assistant, not as the app icon.
- [x] Onboarding artwork does not duplicate Avi when Avi is already rendered
  near the primary call-to-action.
- [x] Splash and onboarding artwork integrate with the app background without
  visible rectangular canvas edges.
- [x] Any embedded AV mark uses the canonical AVALSYS monogram.
- [x] AV mark is small and secondary, not the primary product icon.
- [x] Avi is not used as the app icon, product logo, or wordmark.
- [x] Avi artwork appears only where the submitted app actually shows Avi.
- [x] Screenshots show real release-candidate UI.
- [x] No screenshot frame hides legal, account, credit, deletion, or export
  state copy.
- [x] No generated or approximate AV marks are present.
- [x] No archived/experimental Avi explorations are used as production sources.

## Verification

Before opening the asset PR:

- [x] Compare app icon at small home-screen sizes.
- [x] Compare App Store icon at full resolution.
- [x] Clean-install the app and verify native launch, splash, and onboarding
  appear in order.
- [x] Confirm native launch shows Animate AV logo plus icon, not copied branding
  from another Apps AV app.
- [x] Confirm splash and onboarding use product-specific Animate AV artwork.
- [x] Confirm dark/light appearance where relevant.
- [x] Confirm Reduce Transparency/Increase Contrast do not break app UI around
  the asset.
- [x] Confirm screenshots contain no private user data.
- [x] Confirm App Store metadata and screenshot captions match the visible UI.
- [x] Run public readiness checks after integrating the approved assets.

```bash
scripts/check-public-release-readiness.sh
```

## Gate Update

The approved runtime asset paths above are the public canonical paths for the
initial iOS branding package. When replacing them, update this handoff and the
public readiness gate together.
