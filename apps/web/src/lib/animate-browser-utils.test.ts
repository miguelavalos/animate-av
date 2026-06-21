import { describe, expect, test } from "bun:test";
import {
  createSourceLocalIdentifier,
  fileTypeError,
  imageFileExtension,
  isSupportedSourceImageFile,
  loadGalleryRecords,
  loadLocalInProgressJobs,
  sourceImageAccept
} from "./animate-browser-utils";

describe("Animate browser source utilities", () => {
  test("builds stable local source identifiers from file metadata", () => {
    const file = new File(["source"], "source.png", {
      lastModified: 1_700_000_000_000,
      type: "image/png"
    });

    expect(`${createSourceLocalIdentifier(file)}:full`).toBe("web:source.png:6:1700000000000:full");
    expect(`${createSourceLocalIdentifier(file)}:portrait`).toBe("web:source.png:6:1700000000000:portrait");
  });

  test("accepts only supported source image formats", () => {
    expect(sourceImageAccept).not.toContain("image/*");
    expect(sourceImageAccept).toContain(".heic");
    expect(sourceImageAccept).toContain("image/webp");

    for (const [name, type] of [
      ["source.jpg", "image/jpeg"],
      ["source.png", "image/png"],
      ["source.heic", "image/heic"],
      ["source.heif", "image/heif"],
      ["source.webp", "image/webp"]
    ]) {
      const file = new File(["source"], name, { type });
      expect(isSupportedSourceImageFile(file)).toBe(true);
      expect(fileTypeError(file)).toBeNull();
    }
  });

  test("accepts supported source image extensions when mime type is unavailable", () => {
    for (const name of ["source.JPG", "source.png", "source.HEIC", "source.heif", "source.webp"]) {
      const file = new File(["source"], name);
      expect(isSupportedSourceImageFile(file)).toBe(true);
      expect(fileTypeError(file)).toBeNull();
    }
  });

  test("rejects unsupported image and non-image formats", () => {
    for (const [name, type] of [
      ["source.svg", "image/svg+xml"],
      ["source.gif", "image/gif"],
      ["source.tiff", "image/tiff"],
      ["source.avif", "image/avif"],
      ["source.pdf", "application/pdf"],
      ["source", ""]
    ]) {
      const file = new File(["source"], name, { type });
      expect(isSupportedSourceImageFile(file)).toBe(false);
      expect(fileTypeError(file)).toBe("Choose a JPG, PNG, HEIC, or WebP image.");
    }
  });

  test("rejects supported source images above the size limit", () => {
    const file = new File([new Uint8Array((25 * 1024 * 1024) + 1)], "source.png", { type: "image/png" });

    expect(isSupportedSourceImageFile(file)).toBe(true);
    expect(fileTypeError(file)).toBe("Choose an image under 25 MB.");
  });

  test("keeps generated image filenames aligned to their mime type", () => {
    expect(imageFileExtension("image/png")).toBe("png");
    expect(imageFileExtension("image/webp")).toBe("webp");
    expect(imageFileExtension("image/heic")).toBe("heic");
    expect(imageFileExtension("image/heif")).toBe("heif");
    expect(imageFileExtension("image/jpeg")).toBe("jpg");
    expect(imageFileExtension("")).toBe("jpg");
  });

  test("ignores non-array gallery records from older browser storage", () => {
    const localStorage = installLocalStorageMock();
    localStorage.setItem("animate-av.gallery.videos.v1", JSON.stringify({ artifactId: "old" }));

    expect(loadGalleryRecords()).toEqual([]);

    localStorage.removeItem("animate-av.gallery.videos.v1");
  });

  test("ignores malformed gallery entries from older browser storage arrays", () => {
    const localStorage = installLocalStorageMock();
    localStorage.setItem("animate-av.gallery.videos.v1", JSON.stringify([
      null,
      "old",
      { id: "missing-artifact" },
      { id: "saved", artifactId: "artifact-1" }
    ]));

    expect(loadGalleryRecords()).toEqual([{ id: "saved", artifactId: "artifact-1" }]);

    localStorage.removeItem("animate-av.gallery.videos.v1");
  });

  test("ignores non-array in-progress jobs from older browser storage", () => {
    const localStorage = installLocalStorageMock();
    localStorage.setItem("animate-av.in-progress.jobs.v1", JSON.stringify({ id: "old" }));

    expect(loadLocalInProgressJobs()).toEqual([]);

    localStorage.removeItem("animate-av.in-progress.jobs.v1");
  });

  test("ignores malformed in-progress entries from older browser storage arrays", () => {
    const localStorage = installLocalStorageMock();
    localStorage.setItem("animate-av.in-progress.jobs.v1", JSON.stringify([
      null,
      "old",
      { id: "missing-title", updatedAt: 1 },
      { id: "valid", title: "Valid job", status: "running", updatedAt: 2 }
    ]));

    expect(loadLocalInProgressJobs()).toEqual([{ id: "valid", title: "Valid job", status: "running", updatedAt: 2 }]);

    localStorage.removeItem("animate-av.in-progress.jobs.v1");
  });
});

function installLocalStorageMock() {
  const values = new Map<string, string>();
  const localStorage = {
    getItem: (key: string) => values.get(key) ?? null,
    removeItem: (key: string) => {
      values.delete(key);
    },
    setItem: (key: string, value: string) => {
      values.set(key, value);
    }
  };
  Object.assign(globalThis, { window: { localStorage }, localStorage });
  return localStorage;
}
