import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

describe("Animate destructive web actions", () => {
  const gallerySource = readFileSync(new URL("./gallery.tsx", import.meta.url), "utf8");
  const inProgressSource = readFileSync(new URL("./in-progress.tsx", import.meta.url), "utf8");
  const textSource = readFileSync(new URL("../lib/animate-i18n.ts", import.meta.url), "utf8");

  it("confirms before clearing downloaded gallery videos", () => {
    expect(gallerySource).toContain("window.confirm(copy.confirmClearLocal)");
    expect(gallerySource).toContain("deleteGalleryRecord(record.id)");
    expect(textSource).toContain("confirmClearLocal");
  });

  it("confirms before deleting realtime jobs or clearing local jobs", () => {
    expect(inProgressSource).toContain('job.source === "realtime" ? copy.confirmDelete : copy.confirmClearLocal');
    expect(inProgressSource).toContain("window.confirm(confirmMessage)");
    expect(inProgressSource).toContain("api.deleteVideoJob(job.id)");
    expect(textSource).toContain("confirmDelete");
  });
});
