import { beforeEach, describe, expect, test } from "bun:test";
import { deleteGalleryRecord, deleteLocalInProgressJob, deleteLocalInProgressJobsByReference, galleryRemoteVideosAvailableForDownload, isDownloadableRemoteVideoArtifact, loadGalleryRecords, loadGalleryRecordsWithObjectUrls, loadLocalInProgressJobs, renameGalleryRecord, saveGalleryRecord, saveGalleryRecordWithBlob, saveLocalInProgressJob, subscribeGalleryRecords, subscribeLocalInProgressJobs } from "./animate-browser-utils";

const storage = new Map<string, string>();
const listeners = new Map<string, Set<EventListener>>();

Object.defineProperty(globalThis, "window", {
  configurable: true,
  value: {
    localStorage: {
      getItem: (key: string) => storage.get(key) ?? null,
      setItem: (key: string, value: string) => storage.set(key, value),
      removeItem: (key: string) => storage.delete(key)
    },
    addEventListener: (eventName: string, listener: EventListener) => {
      const nextListeners = listeners.get(eventName) ?? new Set<EventListener>();
      nextListeners.add(listener);
      listeners.set(eventName, nextListeners);
    },
    removeEventListener: (eventName: string, listener: EventListener) => {
      listeners.get(eventName)?.delete(listener);
    },
    dispatchEvent: (event: Event) => {
      for (const listener of listeners.get(event.type) ?? []) {
        listener(event);
      }
      return true;
    }
  }
});

describe("Animate local gallery records", () => {
  beforeEach(() => {
    storage.clear();
    listeners.clear();
  });

  test("saves records newest first and dedupes by artifact", () => {
    saveGalleryRecord(record("artifact-1", "First"));
    saveGalleryRecord(record("artifact-2", "Second"));
    saveGalleryRecord(record("artifact-1", "First renamed"));

    expect(loadGalleryRecords().map((entry) => entry.title)).toEqual(["First renamed", "Second"]);
  });

  test("renames and deletes local records without backend mutation", () => {
    saveGalleryRecord(record("artifact-1", "First"));
    renameGalleryRecord("artifact-1", "Final title");
    expect(loadGalleryRecords()[0]?.title).toBe("Final title");

    deleteGalleryRecord("artifact-1");
    expect(loadGalleryRecords()).toEqual([]);
  });

  test("keeps local metadata without reusing stale object URLs when blob storage is unavailable", async () => {
    await saveGalleryRecordWithBlob(record("artifact-1", "First"), new Blob(["video"], { type: "video/mp4" }));

    expect(loadGalleryRecords()[0]?.blobKey).toBe("artifact-1");
    expect(loadGalleryRecords()[0]?.objectUrl).toBeUndefined();
    const hydratedRecord = (await loadGalleryRecordsWithObjectUrls())[0];
    expect(hydratedRecord?.title).toBe("First");
    expect(hydratedRecord?.objectUrl).toBeUndefined();
    expect(hydratedRecord?.localAvailability).toBe("localFileMissing");
  });

  test("keeps remote downloads visible when matching local metadata lost its file", () => {
    const remoteArtifacts = [
      artifact("artifact-1", "final_video"),
      artifact("artifact-2", "final_video"),
      artifact("artifact-3", "source_image")
    ];
    const records = [
      { ...record("artifact-1", "Saved"), localAvailability: "savedOnDevice" as const },
      { ...record("artifact-2", "Missing"), objectUrl: undefined, localAvailability: "localFileMissing" as const }
    ];

    expect(galleryRemoteVideosAvailableForDownload(remoteArtifacts, records).map((entry) => entry.id)).toEqual(["artifact-2"]);
  });

  test("offers remote downloads only for available unexpired final videos", () => {
    const now = 1_700_000_000_000;
    expect(isDownloadableRemoteVideoArtifact(artifact("artifact-1", "final_video", { status: "available", expiresAt: now + 1 }), now)).toBe(true);
    expect(isDownloadableRemoteVideoArtifact(artifact("artifact-2", "final_video", { status: "ready", expiresAt: now + 1 }), now)).toBe(true);
    expect(isDownloadableRemoteVideoArtifact(artifact("artifact-3", "final_video", { status: "completed", expiresAt: now + 1 }), now)).toBe(true);
    expect(isDownloadableRemoteVideoArtifact(artifact("artifact-4", "final_video", { status: "failed", expiresAt: now + 1 }), now)).toBe(false);
    expect(isDownloadableRemoteVideoArtifact(artifact("artifact-5", "final_video", { status: "available", expiresAt: now }), now)).toBe(false);
    expect(isDownloadableRemoteVideoArtifact(artifact("artifact-6", "source_image", { status: "available", expiresAt: now + 1 }), now)).toBe(false);

    expect(galleryRemoteVideosAvailableForDownload([
      artifact("available-video", "final_video", { status: "available", expiresAt: now + 1 }),
      artifact("expired-video", "final_video", { status: "available", expiresAt: now - 1 }),
      artifact("failed-video", "final_video", { status: "failed", expiresAt: now + 1 })
    ], [], now).map((entry) => entry.id)).toEqual(["available-video"]);
  });

  test("notifies same-tab subscribers when gallery records change", () => {
    let notificationCount = 0;
    const unsubscribe = subscribeGalleryRecords(() => {
      notificationCount += 1;
    });

    saveGalleryRecord(record("artifact-1", "First"));
    renameGalleryRecord("artifact-1", "Renamed");
    deleteGalleryRecord("artifact-1");
    unsubscribe();
    saveGalleryRecord(record("artifact-2", "Second"));

    expect(notificationCount).toBe(3);
  });

  test("notifies gallery subscribers when another tab changes records", () => {
    let notificationCount = 0;
    subscribeGalleryRecords(() => {
      notificationCount += 1;
    });

    window.dispatchEvent(Object.assign(new Event("storage"), { key: "animate-av.gallery.videos.v1" }));
    window.dispatchEvent(Object.assign(new Event("storage"), { key: "unrelated" }));

    expect(notificationCount).toBe(1);
  });
});

describe("Animate local in-progress jobs", () => {
  beforeEach(() => {
    storage.clear();
    listeners.clear();
  });

  test("saves newest jobs first, dedupes, and caps retained local jobs", () => {
    for (let index = 0; index < 22; index += 1) {
      saveLocalInProgressJob(job(`job-${index}`, `Job ${index}`));
    }
    saveLocalInProgressJob(job("job-5", "Job 5 updated"));

    const jobs = loadLocalInProgressJobs();
    expect(jobs).toHaveLength(20);
    expect(jobs[0]?.title).toBe("Job 5 updated");
    expect(jobs.filter((entry) => entry.id === "job-5")).toHaveLength(1);
  });

  test("clears a local in-progress job without backend mutation", () => {
    saveLocalInProgressJob(job("job-1", "Queued"));
    deleteLocalInProgressJob("job-1");
    expect(loadLocalInProgressJobs()).toEqual([]);
  });

  test("clears local in-progress mirrors by any backend job reference", () => {
    saveLocalInProgressJob(job("local-1", "Queued", {
      videoId: "video-1",
      renderJobId: "render-1",
      workflowRunId: "workflow-1"
    }));
    saveLocalInProgressJob(job("local-2", "Other", {
      videoId: "video-2",
      renderJobId: "render-2",
      workflowRunId: "workflow-2"
    }));

    deleteLocalInProgressJobsByReference([" render-1 ", "missing"]);

    expect(loadLocalInProgressJobs().map((entry) => entry.id)).toEqual(["local-2"]);

    deleteLocalInProgressJobsByReference(["workflow-2"]);
    expect(loadLocalInProgressJobs()).toEqual([]);
  });

  test("notifies same-tab subscribers when local in-progress jobs change", () => {
    let notificationCount = 0;
    const unsubscribe = subscribeLocalInProgressJobs(() => {
      notificationCount += 1;
    });

    saveLocalInProgressJob(job("job-1", "Queued"));
    deleteLocalInProgressJob("job-1");
    unsubscribe();
    saveLocalInProgressJob(job("job-2", "Queued"));

    expect(notificationCount).toBe(2);
  });

  test("notifies subscribers when another tab changes local in-progress jobs", () => {
    let notificationCount = 0;
    subscribeLocalInProgressJobs(() => {
      notificationCount += 1;
    });

    window.dispatchEvent(Object.assign(new Event("storage"), { key: "animate-av.in-progress.jobs.v1" }));
    window.dispatchEvent(Object.assign(new Event("storage"), { key: "unrelated" }));

    expect(notificationCount).toBe(1);
  });
});

function record(artifactId: string, title: string) {
  return {
    id: artifactId,
    videoId: `video-${artifactId}`,
    artifactId,
    title,
    blobKey: artifactId,
    r2Key: `r2/${artifactId}.mp4`,
    objectUrl: `blob:${artifactId}`,
    createdAt: Date.now()
  };
}

function artifact(id: string, kind: string, overrides: Partial<ReturnType<typeof baseArtifact>> = {}) {
  return {
    ...baseArtifact(id, kind),
    ...overrides
  };
}

function baseArtifact(id: string, kind: string) {
  return {
    id,
    kind,
    status: "available",
    title: `Artifact ${id}`,
    r2Key: `r2/${id}.mp4`,
    createdAt: Date.now(),
    expiresAt: Date.now() + 60_000
  };
}

function job(id: string, title: string, overrides: Partial<ReturnType<typeof baseJob>> = {}) {
  return {
    ...baseJob(id, title),
    ...overrides
  };
}

function baseJob(id: string, title: string) {
  return {
    id,
    videoId: `video-${id}`,
    title,
    status: "queued" as const,
    phase: "queued",
    createdAt: Date.now(),
    updatedAt: Date.now()
  };
}
