import { describe, expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { AppsAvLocale } from "@avalsys/apps-av-web";
import { getAnimateLookFamilyCopy, getAnimateLookTitle } from "./animate-i18n";
import { animateFinalRenderLookValues, animateLookFamilies, animateLookPreviewAssets, isAnimateFinalRenderLook, isAnimateLook } from "./animate-models";

const locales: AppsAvLocale[] = ["en", "es", "fr", "de", "ca"];

describe("Animate look families", () => {
  test("matches the iOS 8 by 8 look matrix without duplicate slots", () => {
    const looks = animateLookFamilies.flatMap((family) => family.looks);

    expect(animateLookFamilies).toHaveLength(8);
    expect(animateLookFamilies.every((family) => family.looks.length === 8)).toBe(true);
    expect(new Set(looks).size).toBe(64);
  });

  test("has one unique copied preview asset for every look", () => {
    const looks = animateLookFamilies.flatMap((family) => family.looks);
    const paths = looks.map((look) => animateLookPreviewAssets[look].path);
    const assetNames = looks.map((look) => animateLookPreviewAssets[look].assetName);

    expect(new Set(paths).size).toBe(64);
    expect(new Set(assetNames).size).toBe(64);

    for (const assetPath of paths) {
      expect(existsSync(join(import.meta.dir, "../../public", assetPath.replace(/^\//, "")))).toBe(true);
    }
  });

  test("has localized labels for every family and look", () => {
    const looks = animateLookFamilies.flatMap((family) => family.looks);

    for (const locale of locales) {
      for (const family of animateLookFamilies) {
        const copy = getAnimateLookFamilyCopy(family.id, locale);
        expect(copy.title.length).toBeGreaterThan(0);
        expect(copy.subtitle.length).toBeGreaterThan(0);
      }

      for (const look of looks) {
        expect(getAnimateLookTitle(look, locale).length).toBeGreaterThan(0);
      }
    }
  });

  test("keeps selectable final-render looks aligned to the current backend contract", () => {
    const looks = animateLookFamilies.flatMap((family) => family.looks);

    expect(animateFinalRenderLookValues).toHaveLength(32);
    expect(new Set(animateFinalRenderLookValues).size).toBe(32);
    expect(animateFinalRenderLookValues.every((look) => looks.includes(look))).toBe(true);
    expect(looks.filter(isAnimateFinalRenderLook)).toHaveLength(32);
  });

  test("accepts only known look ids for localized runtime labels", () => {
    expect(isAnimateLook("cartoon")).toBe(true);
    expect(isAnimateLook("not-a-look")).toBe(false);
    expect(isAnimateLook("")).toBe(false);
    expect(isAnimateLook(undefined)).toBe(false);
  });
});
