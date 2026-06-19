import type { AnimateArtifact, AnimateGalleryVideoRecord, AnimateLocalInProgressJob, AnimateVideoFeedback, AnimateVideoFeedbackScore } from "@/lib/animate-models";

const galleryRecordsKey = "animate-av.gallery.videos.v1";
const inProgressRecordsKey = "animate-av.in-progress.jobs.v1";
const galleryBlobDatabaseName = "animate-av-gallery-videos";
const galleryBlobStoreName = "video-blobs";
const galleryBlobDatabaseVersion = 1;
const maxSourceImageBytes = 25 * 1024 * 1024;
const galleryRecordsChangedEvent = "animate-av:gallery-records-changed";
const localInProgressJobsChangedEvent = "animate-av:local-in-progress-jobs-changed";
const supportedSourceImageMimeTypes = new Set([
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/heic",
  "image/heif",
  "image/webp"
]);
const supportedSourceImageExtensions = new Set(["jpg", "jpeg", "png", "heic", "heif", "webp"]);
export const sourceImageAccept = ".jpg,.jpeg,.png,.heic,.heif,.webp,image/jpeg,image/png,image/heic,image/heif,image/webp";
const normalizedSourceImageType = "image/jpeg";
const normalizedSourceImageQuality = 0.9;
const portraitFrameWidth = 1024;
const portraitFrameHeight = 1792;

export function createVideoId() {
  return `animate-web-video-${crypto.randomUUID()}`;
}

export function createSourceLocalIdentifier(file: File) {
  return `web:${file.name}:${file.size}:${file.lastModified}`;
}

export async function sha256Hex(file: File) {
  const digest = await crypto.subtle.digest("SHA-256", await file.arrayBuffer());
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function readImageDimensions(file: File, readErrorMessage = "Selected image could not be read.") {
  const url = URL.createObjectURL(file);
  try {
    const image = await loadImage(url, readErrorMessage);
    return { width: image.naturalWidth, height: image.naturalHeight };
  } finally {
    URL.revokeObjectURL(url);
  }
}

export async function normalizeSourceImageFile(file: File, readErrorMessage = "Selected image could not be read.") {
  const url = URL.createObjectURL(file);
  try {
    const image = await loadImage(url, readErrorMessage);
    const canvas = document.createElement("canvas");
    canvas.width = image.naturalWidth;
    canvas.height = image.naturalHeight;
    const context = canvas.getContext("2d");
    if (!context) {
      throw new Error(readErrorMessage);
    }
    context.drawImage(image, 0, 0);
    return await canvasToFile(canvas, normalizedFilename(file.name), file.lastModified, readErrorMessage);
  } finally {
    URL.revokeObjectURL(url);
  }
}

export async function createPortraitFrameFile(file: File, readErrorMessage = "Selected image could not be read.") {
  const url = URL.createObjectURL(file);
  try {
    const image = await loadImage(url, readErrorMessage);

    const sourceWidth = image.naturalWidth;
    const sourceHeight = image.naturalHeight;
    const canvas = document.createElement("canvas");
    canvas.width = portraitFrameWidth;
    canvas.height = portraitFrameHeight;
    const context = canvas.getContext("2d");
    if (!context) {
      throw new Error(readErrorMessage);
    }

    const coverScale = Math.max(portraitFrameWidth / sourceWidth, portraitFrameHeight / sourceHeight);
    const coverWidth = Math.ceil(sourceWidth * coverScale);
    const coverHeight = Math.ceil(sourceHeight * coverScale);
    const coverX = Math.round((portraitFrameWidth - coverWidth) / 2);
    const coverY = Math.round((portraitFrameHeight - coverHeight) / 2);
    context.save();
    context.filter = "blur(28px)";
    context.drawImage(image, coverX, coverY, coverWidth, coverHeight);
    context.restore();
    context.fillStyle = "rgba(255, 255, 255, 0.18)";
    context.fillRect(0, 0, portraitFrameWidth, portraitFrameHeight);

    const containScale = Math.min(portraitFrameWidth / sourceWidth, portraitFrameHeight / sourceHeight);
    const containWidth = Math.round(sourceWidth * containScale);
    const containHeight = Math.round(sourceHeight * containScale);
    const containX = Math.round((portraitFrameWidth - containWidth) / 2);
    const containY = Math.round((portraitFrameHeight - containHeight) / 2);
    context.drawImage(image, containX, containY, containWidth, containHeight);

    const baseName = file.name.replace(/\.[^.]+$/, "") || "animate-source-image";
    return await canvasToFile(canvas, `${baseName}-portrait-frame.jpg`, file.lastModified, readErrorMessage);
  } finally {
    URL.revokeObjectURL(url);
  }
}

export function fileTypeError(file: File, copy = {
  imageTooLarge: "Choose an image under 25 MB.",
  unsupportedImageType: "Choose a JPG, PNG, HEIC, or WebP image."
}) {
  if (!isSupportedSourceImageFile(file)) {
    return copy.unsupportedImageType;
  }
  if (file.size > maxSourceImageBytes) {
    return copy.imageTooLarge;
  }
  return null;
}

export function isSupportedSourceImageFile(file: File) {
  const mimeType = file.type.toLowerCase();
  if (mimeType) {
    return supportedSourceImageMimeTypes.has(mimeType);
  }
  const extension = file.name.toLowerCase().split(".").pop();
  return extension ? supportedSourceImageExtensions.has(extension) : false;
}

export function imageFileExtension(mimeType: string) {
  switch (mimeType.toLowerCase()) {
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    case "image/heic":
      return "heic";
    case "image/heif":
      return "heif";
    default:
      return "jpg";
  }
}

function loadImage(url: string, readErrorMessage: string) {
  const image = new Image();
  return new Promise<HTMLImageElement>((resolve, reject) => {
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(readErrorMessage));
    image.src = url;
  });
}

async function canvasToFile(canvas: HTMLCanvasElement, filename: string, lastModified: number, readErrorMessage: string) {
  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((nextBlob) => {
      if (nextBlob) {
        resolve(nextBlob);
      } else {
        reject(new Error(readErrorMessage));
      }
    }, normalizedSourceImageType, normalizedSourceImageQuality);
  });
  return new File([blob], filename, {
    lastModified,
    type: normalizedSourceImageType
  });
}

function normalizedFilename(filename: string) {
  const baseName = filename.replace(/\.[^.]+$/, "") || "animate-source-image";
  return `${baseName}-normalized.jpg`;
}

export function loadGalleryRecords() {
  if (typeof window === "undefined") {
    return [];
  }
  try {
    const raw = window.localStorage.getItem(galleryRecordsKey);
    return raw ? JSON.parse(raw) as AnimateGalleryVideoRecord[] : [];
  } catch {
    return [];
  }
}

export async function loadGalleryRecordsWithObjectUrls() {
  const records = loadGalleryRecords();
  const storedRecords = await Promise.all(records.map(async (record) => {
    const blob = await loadGalleryBlob(record.blobKey ?? record.artifactId);
    if (!blob) {
      const { objectUrl: _staleObjectUrl, ...metadata } = record;
      return { ...metadata, localAvailability: "localFileMissing" as const };
    }
    return { ...record, objectUrl: URL.createObjectURL(blob), localAvailability: "savedOnDevice" as const };
  }));
  return storedRecords;
}

export function saveGalleryRecord(record: AnimateGalleryVideoRecord) {
  if (typeof window === "undefined") {
    return;
  }
  const records = loadGalleryRecords().filter((entry) => entry.artifactId !== record.artifactId);
  window.localStorage.setItem(galleryRecordsKey, JSON.stringify([record, ...records]));
  notifyGalleryRecordsChanged();
}

export async function saveGalleryRecordWithBlob(record: AnimateGalleryVideoRecord, blob: Blob) {
  const blobKey = record.blobKey ?? record.artifactId;
  await saveGalleryBlob(blobKey, blob);
  const { objectUrl: _temporaryObjectUrl, ...metadata } = record;
  saveGalleryRecord({ ...metadata, blobKey, localAvailability: "savedOnDevice" });
}

export function deleteGalleryRecord(recordId: string) {
  if (typeof window === "undefined") {
    return;
  }
  const existing = loadGalleryRecords().find((entry) => entry.id === recordId);
  if (existing) {
    void deleteGalleryBlob(existing.blobKey ?? existing.artifactId);
  }
  const records = loadGalleryRecords().filter((entry) => entry.id !== recordId);
  window.localStorage.setItem(galleryRecordsKey, JSON.stringify(records));
  notifyGalleryRecordsChanged();
}

export function galleryRemoteVideosAvailableForDownload(artifacts: AnimateArtifact[], records: AnimateGalleryVideoRecord[], now = Date.now()) {
  const savedArtifactIds = new Set(records.filter(hasSavedLocalGalleryFile).map((record) => record.artifactId));
  return artifacts.filter((artifact) => isDownloadableRemoteVideoArtifact(artifact, now) && !savedArtifactIds.has(remoteArtifactIdentifier(artifact)));
}

export function isDownloadableRemoteVideoArtifact(artifact: AnimateArtifact, now = Date.now()) {
  const status = artifact.status.toLowerCase();
  return artifact.kind === "final_video" && ["available", "ready", "completed"].includes(status) && artifact.expiresAt > now;
}

export function hasSavedLocalGalleryFile(record: AnimateGalleryVideoRecord) {
  return record.localAvailability !== "localFileMissing" && Boolean(record.objectUrl);
}

export function remoteArtifactIdentifier(artifact: AnimateArtifact) {
  return artifact.workflowArtifactId ?? artifact.id;
}

export function renameGalleryRecord(recordId: string, title: string) {
  if (typeof window === "undefined") {
    return;
  }
  const trimmed = title.trim();
  if (!trimmed) {
    return;
  }
  const records = loadGalleryRecords().map((entry) => entry.id === recordId ? { ...entry, title: trimmed } : entry);
  window.localStorage.setItem(galleryRecordsKey, JSON.stringify(records));
  notifyGalleryRecordsChanged();
}

export function updateGalleryRecordFeedback(recordId: string, key: keyof Omit<AnimateVideoFeedback, "updatedAt">, score: AnimateVideoFeedbackScore) {
  if (typeof window === "undefined") {
    return;
  }
  const records = loadGalleryRecords().map((entry) => {
    if (entry.id !== recordId) {
      return entry;
    }
    return {
      ...entry,
      feedback: {
        ...entry.feedback,
        [key]: score,
        updatedAt: Date.now()
      }
    };
  });
  window.localStorage.setItem(galleryRecordsKey, JSON.stringify(records));
  notifyGalleryRecordsChanged();
}

export function subscribeGalleryRecords(listener: () => void) {
  if (typeof window === "undefined") {
    return () => {};
  }
  const onStorage = (event: StorageEvent) => {
    if (event.key === galleryRecordsKey) {
      listener();
    }
  };
  window.addEventListener(galleryRecordsChangedEvent, listener);
  window.addEventListener("storage", onStorage);
  return () => {
    window.removeEventListener(galleryRecordsChangedEvent, listener);
    window.removeEventListener("storage", onStorage);
  };
}

export function downloadBlobUrl(blob: Blob, filename: string) {
  const objectUrl = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = objectUrl;
  anchor.download = filename;
  document.body.append(anchor);
  anchor.click();
  anchor.remove();
  return objectUrl;
}

export function loadLocalInProgressJobs() {
  if (typeof window === "undefined") {
    return [];
  }
  try {
    const raw = window.localStorage.getItem(inProgressRecordsKey);
    return raw ? JSON.parse(raw) as AnimateLocalInProgressJob[] : [];
  } catch {
    return [];
  }
}

export function saveLocalInProgressJob(job: AnimateLocalInProgressJob) {
  if (typeof window === "undefined") {
    return;
  }
  const jobs = loadLocalInProgressJobs().filter((entry) => entry.id !== job.id);
  window.localStorage.setItem(inProgressRecordsKey, JSON.stringify([job, ...jobs].slice(0, 20)));
  notifyLocalInProgressJobsChanged();
}

export function deleteLocalInProgressJob(jobId: string) {
  if (typeof window === "undefined") {
    return;
  }
  window.localStorage.setItem(inProgressRecordsKey, JSON.stringify(loadLocalInProgressJobs().filter((entry) => entry.id !== jobId)));
  notifyLocalInProgressJobsChanged();
}

export function deleteLocalInProgressJobsByReference(references: Array<string | null | undefined>) {
  if (typeof window === "undefined") {
    return;
  }
  const referenceSet = new Set(references.map((reference) => reference?.trim()).filter(isNonEmptyString));
  if (referenceSet.size === 0) {
    return;
  }
  const remainingJobs = loadLocalInProgressJobs().filter((entry) => !localInProgressJobReferences(entry).some((reference) => referenceSet.has(reference)));
  window.localStorage.setItem(inProgressRecordsKey, JSON.stringify(remainingJobs));
  notifyLocalInProgressJobsChanged();
}

export function subscribeLocalInProgressJobs(listener: () => void) {
  if (typeof window === "undefined") {
    return () => {};
  }
  const onStorage = (event: StorageEvent) => {
    if (event.key === inProgressRecordsKey) {
      listener();
    }
  };
  window.addEventListener(localInProgressJobsChangedEvent, listener);
  window.addEventListener("storage", onStorage);
  return () => {
    window.removeEventListener(localInProgressJobsChangedEvent, listener);
    window.removeEventListener("storage", onStorage);
  };
}

function notifyLocalInProgressJobsChanged() {
  window.dispatchEvent(new Event(localInProgressJobsChangedEvent));
}

function notifyGalleryRecordsChanged() {
  window.dispatchEvent(new Event(galleryRecordsChangedEvent));
}

function localInProgressJobReferences(job: AnimateLocalInProgressJob) {
  return [
    job.id,
    job.videoId,
    job.renderJobId,
    job.workflowRunId
  ].filter(isNonEmptyString);
}

function isNonEmptyString(value: string | null | undefined): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

async function saveGalleryBlob(key: string, blob: Blob) {
  const database = await openGalleryBlobDatabase();
  if (!database) {
    return;
  }
  await runBlobTransaction(database, "readwrite", (store) => store.put(blob, key));
  database.close();
}

async function loadGalleryBlob(key: string) {
  const database = await openGalleryBlobDatabase();
  if (!database) {
    return null;
  }
  const blob = await runBlobTransaction<Blob | undefined>(database, "readonly", (store) => store.get(key) as IDBRequest<Blob | undefined>);
  database.close();
  return blob ?? null;
}

async function deleteGalleryBlob(key: string) {
  const database = await openGalleryBlobDatabase();
  if (!database) {
    return;
  }
  await runBlobTransaction(database, "readwrite", (store) => store.delete(key));
  database.close();
}

async function openGalleryBlobDatabase() {
  if (typeof indexedDB === "undefined") {
    return null;
  }
  return new Promise<IDBDatabase | null>((resolve) => {
    const request = indexedDB.open(galleryBlobDatabaseName, galleryBlobDatabaseVersion);
    request.onupgradeneeded = () => {
      request.result.createObjectStore(galleryBlobStoreName);
    };
    request.onerror = () => resolve(null);
    request.onsuccess = () => resolve(request.result);
  });
}

function runBlobTransaction<T = undefined>(database: IDBDatabase, mode: IDBTransactionMode, operation: (store: IDBObjectStore) => IDBRequest<T>) {
  return new Promise<T | undefined>((resolve, reject) => {
    const transaction = database.transaction(galleryBlobStoreName, mode);
    const request = operation(transaction.objectStore(galleryBlobStoreName));
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    transaction.onerror = () => reject(transaction.error);
  });
}
