import { describe, expect, test } from "bun:test";
import { animateTranslations, localizedAppPath } from "./animate-i18n";

describe("Animate localized paths", () => {
  test("adds non-English locale to plain paths", () => {
    expect(localizedAppPath("/create", "es")).toBe("/create?lang=es");
  });

  test("preserves existing query params while replacing stale locale", () => {
    expect(localizedAppPath("/gallery?tab=ready&lang=fr", "ca")).toBe("/gallery?tab=ready&lang=ca");
  });

  test("removes locale query for English routes", () => {
    expect(localizedAppPath("/avi?lang=de&source=home", "en")).toBe("/avi?source=home");
  });

  test("keeps hash anchors after locale normalization", () => {
    expect(localizedAppPath("/sign-in?next=create#account", "de")).toBe("/sign-in?next=create&lang=de#account");
  });
});

describe("Animate localized UI contract", () => {
  test("does not reintroduce voice, narrator, or audio controls in visible copy", () => {
    const bannedUiTerms = /\b(voice|narrator|tts|audio|tone|duration|spoken|voz|narrador|tono|duración|parlé|voix|narrateur|ton|durée|stimme|sprecher|tonfall|dauer|veu|durada)\b/i;
    const allCopy = Object.entries(animateTranslations).flatMap(([locale, text]) => flattenCopy(text).map((value) => `${locale}:${value}`));

    expect(allCopy.filter((value) => bannedUiTerms.test(value))).toEqual([]);
  });
});

function flattenCopy(value: unknown): string[] {
  if (typeof value === "string") {
    return [value];
  }
  if (Array.isArray(value)) {
    return value.flatMap(flattenCopy);
  }
  if (value && typeof value === "object") {
    return Object.values(value).flatMap(flattenCopy);
  }
  return [];
}
