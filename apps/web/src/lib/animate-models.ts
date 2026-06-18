export const animateLookFamilies = [
  {
    id: "popular",
    title: "Popular",
    subtitle: "Core animated styles.",
    looks: ["cartoon", "anime", "cinematic3d", "comic", "manga", "clay", "watercolor", "paperCut"]
  },
  {
    id: "cuteSocial",
    title: "Cute social",
    subtitle: "Friendly compact characters.",
    looks: ["plush", "sticker", "chibi", "miniAvatar", "toyFigure", "soft3d", "kawaiiPop", "rubberHose"]
  },
  {
    id: "comicsInk",
    title: "Comics and ink",
    subtitle: "Panels, linework, and contrast.",
    looks: ["americanComic", "euroComic", "heroicComic", "noirInk", "editorialCaricature", "graphicNovel", "sundayStrip", "inkWash"]
  },
  {
    id: "animeManga",
    title: "Anime and manga",
    subtitle: "Expressive anime variants.",
    looks: ["shonenAction", "cozySliceOfLife", "magicalFantasyAnime", "cyberAnime", "blackWhiteManga", "shojoRomance", "superDeformed", "animeWatercolor"]
  },
  {
    id: "paintedHandmade",
    title: "Painted handmade",
    subtitle: "Traditional media texture.",
    looks: ["pencilSketch", "charcoal", "oilPainting", "pastelDream", "storybook", "inkMarker", "crayonKids", "acrylicPoster"]
  },
  {
    id: "digitalGame",
    title: "Digital game",
    subtitle: "Graphic and game-inspired worlds.",
    looks: ["pixel", "neon", "flatVector", "lowPoly", "voxelWorld", "synthwave", "glitchArt", "isometricGame"]
  },
  {
    id: "fantasyWorlds",
    title: "Fantasy worlds",
    subtitle: "Adventure and genre scenes.",
    looks: ["fantasyQuest", "darkFantasy", "sciFiSpace", "steampunk", "pirateStory", "fairytale", "mythicEpic", "yellowComedy"]
  },
  {
    id: "craftTexture",
    title: "Craft texture",
    subtitle: "Physical material charm.",
    looks: ["stopMotion", "feltCraft", "collageCutout", "cardboardTheater", "origami", "stainedGlass", "embroideredTextile", "vintagePoster"]
  }
] as const;

export type AnimateLook = (typeof animateLookFamilies)[number]["looks"][number];
export type AnimateLookFamilyId = (typeof animateLookFamilies)[number]["id"];

export const animateFinalRenderLookValues = [
  "cartoon",
  "anime",
  "cinematic3d",
  "watercolor",
  "comic",
  "manga",
  "clay",
  "paperCut",
  "plush",
  "sticker",
  "pixel",
  "neon",
  "storybook",
  "yellowComedy",
  "soft3d",
  "darkFantasy",
  "vintagePoster",
  "pencilSketch",
  "editorialCaricature",
  "euroComic",
  "americanComic",
  "stopMotion",
  "blackWhiteManga",
  "toyFigure",
  "chibi",
  "flatVector",
  "pastelDream",
  "heroicComic",
  "noirInk",
  "rubberHose",
  "fantasyQuest",
  "miniAvatar"
] as const satisfies readonly AnimateLook[];

const animateFinalRenderLookSet = new Set<AnimateLook>(animateFinalRenderLookValues);
const animateLookSet = new Set<AnimateLook>(animateLookFamilies.flatMap((family) => family.looks));

export function isAnimateFinalRenderLook(look: AnimateLook) {
  return animateFinalRenderLookSet.has(look);
}

export function isAnimateLook(look: string | null | undefined): look is AnimateLook {
  return Boolean(look && animateLookSet.has(look as AnimateLook));
}

export const animateLookTitles: Record<AnimateLook, string> = {
  acrylicPoster: "Acrylic poster",
  americanComic: "American comic",
  animeWatercolor: "Anime watercolor",
  anime: "Anime",
  blackWhiteManga: "Black and white manga",
  cardboardTheater: "Cardboard theater",
  cartoon: "Cartoon",
  charcoal: "Charcoal",
  chibi: "Chibi",
  cinematic3d: "Cinematic 3D",
  clay: "Clay",
  collageCutout: "Collage cutout",
  comic: "Comic",
  cozySliceOfLife: "Cozy slice of life",
  crayonKids: "Crayon kids",
  cyberAnime: "Cyber anime",
  darkFantasy: "Dark fantasy",
  editorialCaricature: "Editorial caricature",
  embroideredTextile: "Embroidered textile",
  euroComic: "Euro comic",
  fairytale: "Fairytale",
  feltCraft: "Felt craft",
  fantasyQuest: "Fantasy quest",
  flatVector: "Flat vector",
  glitchArt: "Glitch art",
  graphicNovel: "Graphic novel",
  heroicComic: "Heroic comic",
  inkMarker: "Ink marker",
  inkWash: "Ink wash",
  isometricGame: "Isometric game",
  kawaiiPop: "Kawaii pop",
  lowPoly: "Low poly",
  magicalFantasyAnime: "Magical fantasy anime",
  manga: "Manga",
  miniAvatar: "Mini avatar",
  mythicEpic: "Mythic epic",
  neon: "Neon",
  noirInk: "Noir ink",
  oilPainting: "Oil painting",
  origami: "Origami",
  paperCut: "Paper cut",
  pastelDream: "Pastel dream",
  pencilSketch: "Pencil sketch",
  pirateStory: "Pirate story",
  pixel: "Pixel",
  plush: "Plush",
  rubberHose: "Rubber hose",
  sciFiSpace: "Sci-fi space",
  shonenAction: "Shonen action",
  shojoRomance: "Shojo romance",
  soft3d: "Soft 3D",
  sticker: "Sticker",
  stopMotion: "Stop motion",
  storybook: "Storybook",
  stainedGlass: "Stained glass",
  steampunk: "Steampunk",
  sundayStrip: "Sunday strip",
  superDeformed: "Super deformed",
  synthwave: "Synthwave",
  toyFigure: "Toy figure",
  vintagePoster: "Vintage poster",
  voxelWorld: "Voxel world",
  watercolor: "Watercolor",
  yellowComedy: "Yellow comedy"
};

export const animateLookPreviewAssets: Record<AnimateLook, { assetName: string; path: string }> = {
  acrylicPoster: lookPreview("LookAcrylicPoster"),
  americanComic: lookPreview("LookAmericanComic"),
  animeWatercolor: lookPreview("LookAnimeWatercolor"),
  anime: lookPreview("LookAnime"),
  blackWhiteManga: lookPreview("LookBlackWhiteManga"),
  cardboardTheater: lookPreview("LookCardboardTheater"),
  cartoon: lookPreview("LookCartoon"),
  charcoal: lookPreview("LookCharcoal"),
  chibi: lookPreview("LookChibi"),
  cinematic3d: lookPreview("LookCinematic3d"),
  clay: lookPreview("LookClay"),
  collageCutout: lookPreview("LookCollageCutout"),
  comic: lookPreview("LookComic"),
  cozySliceOfLife: lookPreview("LookCozySliceOfLife"),
  crayonKids: lookPreview("LookCrayonKids"),
  cyberAnime: lookPreview("LookCyberAnime"),
  darkFantasy: lookPreview("LookDarkFantasy"),
  editorialCaricature: lookPreview("LookEditorialCaricature"),
  embroideredTextile: lookPreview("LookEmbroideredTextile"),
  euroComic: lookPreview("LookEuroComic"),
  fairytale: lookPreview("LookFairytale"),
  feltCraft: lookPreview("LookFeltCraft"),
  fantasyQuest: lookPreview("LookFantasyQuest"),
  flatVector: lookPreview("LookFlatVector"),
  glitchArt: lookPreview("LookGlitchArt"),
  graphicNovel: lookPreview("LookGraphicNovel"),
  heroicComic: lookPreview("LookHeroicComic"),
  inkMarker: lookPreview("LookInkMarker"),
  inkWash: lookPreview("LookInkWash"),
  isometricGame: lookPreview("LookIsometricGame"),
  kawaiiPop: lookPreview("LookKawaiiPop"),
  lowPoly: lookPreview("LookLowPoly"),
  magicalFantasyAnime: lookPreview("LookMagicalFantasyAnime"),
  manga: lookPreview("LookManga"),
  miniAvatar: lookPreview("LookMiniAvatar"),
  mythicEpic: lookPreview("LookMythicEpic"),
  neon: lookPreview("LookNeon"),
  noirInk: lookPreview("LookNoirInk"),
  oilPainting: lookPreview("LookOilPainting"),
  origami: lookPreview("LookOrigami"),
  paperCut: lookPreview("LookPaperCut"),
  pastelDream: lookPreview("LookPastelDream"),
  pencilSketch: lookPreview("LookPencilSketch"),
  pirateStory: lookPreview("LookPirateStory"),
  pixel: lookPreview("LookPixel"),
  plush: lookPreview("LookPlush"),
  rubberHose: lookPreview("LookRubberHose"),
  sciFiSpace: lookPreview("LookSciFiSpace"),
  shonenAction: lookPreview("LookShonenAction"),
  shojoRomance: lookPreview("LookShojoRomance"),
  soft3d: lookPreview("LookSoft3d"),
  sticker: lookPreview("LookSticker"),
  stopMotion: lookPreview("LookStopMotion"),
  storybook: lookPreview("LookStorybook"),
  stainedGlass: lookPreview("LookStainedGlass"),
  steampunk: lookPreview("LookSteampunk"),
  sundayStrip: lookPreview("LookSundayStrip"),
  superDeformed: lookPreview("LookSuperDeformed"),
  synthwave: lookPreview("LookSynthwave"),
  toyFigure: lookPreview("LookToyFigure"),
  vintagePoster: lookPreview("LookVintagePoster"),
  voxelWorld: lookPreview("LookVoxelWorld"),
  watercolor: lookPreview("LookWatercolor"),
  yellowComedy: lookPreview("LookYellowComedy")
};

function lookPreview(assetName: string) {
  return {
    assetName,
    path: `/assets/look-previews/${assetName}.png`
  };
}

export interface AnimateCreditBalance {
  availableCredits?: number;
  spendableCredits?: number;
  videoCreditsAvailable?: number;
  reservedCredits?: number;
  minimumRenderCredits?: number;
  watermarkRemovalCreditCost?: number;
  proMonthly?: number;
  proMonthlyCredits?: number;
  promotional?: number;
  promotionalGrantedCredits?: number;
  purchased?: number;
  purchasedCredits?: number;
  walletSummary?: {
    credits?: {
      available?: number;
      reserved?: number;
      purchasedTotal?: number;
      promoGrantedTotal?: number;
      subscriptionGrantedTotal?: number;
    };
  };
}

export interface AnimatePreparedUpload {
  videoId: string;
  uploadId: string;
  uploadUrl: string;
  method: string;
  headers: Record<string, string>;
  completionUrl?: string | null;
  mediaAsset?: AnimateMediaAsset;
}

export interface AnimateUploadCompletion {
  videoId: string;
  uploadId: string;
  mediaAssetId?: string;
  sourceImageUploadId?: string;
  storageKey?: string;
  r2Key?: string;
}

export interface AnimateRenderPlanResponse {
  videoId: string;
  planId: string;
  canCreateVideo: boolean;
  createVideoBlockers: string[];
  plan: {
    planId?: string;
    totalCreditCost: number;
    duration?: string;
    secondsPerCredit?: number;
  };
  watermark?: {
    selectedRemoveWatermark?: boolean;
    nonProRemovalCreditCost?: number;
    watermarkCreditCost?: number;
  } | null;
  userMessage?: string | null;
}

export interface AnimateConfirmFinalRenderResponse {
  appId?: "animateav";
  videoId: string;
  planId?: string;
  reservation?: {
    id: string;
    amount: number;
    status: "reserved";
    workflowRunId: string | null;
    idempotencyKey: string;
    expiresAt: string;
    createdAt: string;
    updatedAt: string;
  };
  workflow?: {
    appId: "animateav";
    videoId: string;
    renderJobId: string;
    workflowRunId: string;
    status: "queued";
    startedAt: string;
  };
  status?: string;
  confirmedAt?: string;
  userMessage?: string | null;
  renderPlan?: AnimateRenderPlanResponse;
}

export interface AnimateArtifactDownloadResponse {
  downloadUrl: string;
  method: string;
  headers: Record<string, string>;
}

export interface AnimateMediaAsset {
  id: string;
  mediaKind?: string;
  url?: string;
  sourceLocalIdentifier?: string;
  uploadId?: string;
  moderationStatus?: string;
}

export interface AnimateArtifact {
  id: string;
  workflowArtifactId?: string | null;
  workflowRunId?: string | null;
  kind: string;
  status: string;
  title?: string | null;
  look?: string | null;
  r2Key: string;
  createdAt: number;
  expiresAt: number;
}

export interface AnimateVideoJob {
  id: string;
  videoId?: string | null;
  workflowRunId?: string | null;
  renderJobId?: string | null;
  title: string;
  status: string;
  phase?: string | null;
  look?: string | null;
  duration?: string | null;
  durationSeconds?: number | null;
  totalCreditCost?: number | null;
  updatedAt: number;
  assetKind?: "video" | "image";
}

export interface AnimateLocalInProgressJob {
  id: string;
  videoId: string;
  workflowRunId?: string;
  renderJobId?: string;
  title: string;
  status: "queued" | "running" | "completed" | "failed" | "cancelled";
  phase?: string | null;
  look?: string | null;
  totalCreditCost?: number | null;
  createdAt: number;
  updatedAt: number;
}

export interface AnimateGalleryVideoRecord {
  id: string;
  videoId: string;
  artifactId: string;
  title: string;
  r2Key: string;
  objectUrl?: string;
  blobKey?: string;
  localAvailability?: "savedOnDevice" | "localFileMissing";
  sourceImageObjectUrl?: string;
  generatedImageObjectUrl?: string;
  createdAt: number;
}

export interface AnimateCreateDraft {
  videoId: string;
  sourceLocalIdentifier: string;
  sourceImageUploadId?: string;
  originalFilename?: string;
  contentType?: string;
  byteSize?: number;
  width?: number;
  height?: number;
  look: AnimateLook;
  actionHint: string;
  messageText: string;
  startsWithSourcePhoto: boolean;
}
