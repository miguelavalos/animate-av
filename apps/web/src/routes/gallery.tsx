import { AccountUserButton } from "@avalsys/account-av-web";
import { AppShell, useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { Download, Film, Loader2, MoreHorizontal, Pencil, RefreshCw, Trash2 } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { ProtectedRoute } from "@/components/protected-route";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { deleteGalleryRecord, downloadBlobUrl, galleryRemoteVideosAvailableForDownload, hasSavedLocalGalleryFile, loadGalleryRecordsWithObjectUrls, remoteArtifactIdentifier, renameGalleryRecord, saveGalleryRecordWithBlob, subscribeGalleryRecords } from "@/lib/animate-browser-utils";
import { useAnimateApiClient } from "@/lib/animate-client-hooks";
import { useAnimateGalleryArtifacts } from "@/lib/animate-convex";
import { localizedAnimateErrorMessage } from "@/lib/animate-errors";
import { isAnimateLook, type AnimateArtifact, type AnimateGalleryVideoRecord } from "@/lib/animate-models";
import { localizedAppPath, useAnimateLookCopy, useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/gallery")({
  component: GalleryRoute
});

function GalleryRoute() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();
  const copy = text.gallery;

  return (
    <ProtectedRoute>
      <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
        <GallerySurface copy={copy} createHref={localizedAppPath("/create", locale)} errors={text.errors} />
      </AppShell>
    </ProtectedRoute>
  );
}

function GallerySurface({ copy, createHref, errors }: { copy: ReturnType<typeof useAnimateText>["gallery"]; createHref: string; errors: ReturnType<typeof useAnimateText>["errors"] }) {
  const api = useAnimateApiClient();
  const lookCopy = useAnimateLookCopy();
  const remote = useAnimateGalleryArtifacts();
  const [records, setRecords] = useState<AnimateGalleryVideoRecord[]>([]);
  const recordsRef = useRef<AnimateGalleryVideoRecord[]>([]);
  const [renamingId, setRenamingId] = useState<string | null>(null);
  const [draftTitle, setDraftTitle] = useState("");
  const [busyArtifactId, setBusyArtifactId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const replaceRecords = useCallback((nextRecords: AnimateGalleryVideoRecord[]) => {
    const nextObjectUrls = new Set(nextRecords.map((record) => record.objectUrl).filter(Boolean));
    for (const record of recordsRef.current) {
      if (record.objectUrl && !nextObjectUrls.has(record.objectUrl)) {
        URL.revokeObjectURL(record.objectUrl);
      }
    }
    recordsRef.current = nextRecords;
    setRecords(nextRecords);
  }, []);

  useEffect(() => {
    let cancelled = false;
    const refreshRecords = () => {
      void loadGalleryRecordsWithObjectUrls().then((nextRecords) => {
        if (!cancelled) {
          replaceRecords(nextRecords);
        }
      });
    };
    const unsubscribe = subscribeGalleryRecords(refreshRecords);
    refreshRecords();
    return () => {
      cancelled = true;
      unsubscribe();
      for (const record of recordsRef.current) {
        if (record.objectUrl) {
          URL.revokeObjectURL(record.objectUrl);
        }
      }
      recordsRef.current = [];
    };
  }, [replaceRecords]);

  function refresh() {
    void loadGalleryRecordsWithObjectUrls().then(replaceRecords);
  }

  function deleteRecord(record: AnimateGalleryVideoRecord) {
    if (record.objectUrl) {
      URL.revokeObjectURL(record.objectUrl);
    }
    deleteGalleryRecord(record.id);
    refresh();
  }

  function startRename(record: AnimateGalleryVideoRecord) {
    setRenamingId(record.id);
    setDraftTitle(record.title);
  }

  function saveRename(record: AnimateGalleryVideoRecord) {
    renameGalleryRecord(record.id, draftTitle);
    setRenamingId(null);
    setDraftTitle("");
    refresh();
  }

  async function downloadRemoteArtifact(artifact: AnimateArtifact) {
    const artifactId = remoteArtifactIdentifier(artifact);
    const title = artifact.title?.trim() || copy.defaultTitle;
    setBusyArtifactId(artifactId);
    setError(null);
    try {
      const download = await api.prepareArtifactDownload(artifactId);
      const blob = await api.downloadBlob(download);
      const objectUrl = downloadBlobUrl(blob, `${safeName(title)}.mp4`);
      await saveGalleryRecordWithBlob({
        id: artifactId,
        videoId: artifact.id,
        artifactId,
        title,
        r2Key: artifact.r2Key,
        objectUrl,
        blobKey: artifactId,
        createdAt: Date.now()
      }, blob);
      URL.revokeObjectURL(objectUrl);
      refresh();
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, errors));
    } finally {
      setBusyArtifactId(null);
    }
  }

  const remoteVideos = galleryRemoteVideosAvailableForDownload(remote.artifacts, records);

  return (
    <section className="grid gap-6 lg:grid-cols-[1fr_22rem]">
      <Card className="animate-canvas gap-0 rounded-lg border-[#e5c1c7] p-5 text-[#20242e] shadow-lg shadow-[#7b233f]/8 sm:p-6 dark:border-white/12 dark:text-white">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase text-[#b94e70]">{copy.kicker}</p>
            <h1 className="mt-2 text-3xl font-semibold leading-tight">{copy.title}</h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-[#4d5563] dark:text-white/72">
              {copy.body}
            </p>
          </div>
          <Button asChild className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]">
            <a href={createHref}>{copy.createCta}</a>
          </Button>
        </div>

        {error ? <p className="mt-5 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">{error}</p> : null}
        {remote.errorMessage ? <p className="mt-5 rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-800">{remote.errorMessage}</p> : null}

        {remoteVideos.length > 0 ? (
          <div className="mt-8 rounded-lg border border-[#e5c1c7] bg-white/62 p-4 dark:border-white/12 dark:bg-white/6">
            <div className="flex items-center gap-2 text-sm font-semibold text-[#20242e]">
              <RefreshCw className="size-4 text-[#b94e70]" aria-hidden="true" />
              {copy.remoteTitle}
            </div>
            <div className="mt-4 grid gap-3">
              {remoteVideos.map((artifact) => {
                const artifactId = remoteArtifactIdentifier(artifact);
                const title = artifact.title?.trim() || copy.defaultTitle;
                const lookLabel = isAnimateLook(artifact.look) ? lookCopy.titles[artifact.look] : "Animate AV";
                return (
                  <article key={artifactId} className="flex flex-col gap-3 rounded-lg border border-[#e5c1c7] bg-[#fff8f3]/76 p-4 sm:flex-row sm:items-center sm:justify-between dark:border-white/12 dark:bg-white/6">
                    <div>
                      <h2 className="font-semibold">{title}</h2>
                      <p className="mt-1 text-xs text-[#6d5960] dark:text-white/62">{lookLabel} · {new Date(artifact.createdAt).toLocaleString()}</p>
                    </div>
                    <Button type="button" size="sm" className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]" disabled={busyArtifactId === artifactId} onClick={() => void downloadRemoteArtifact(artifact)}>
                      {busyArtifactId === artifactId ? <Loader2 className="size-4 animate-spin" aria-hidden="true" /> : <Download className="size-4" aria-hidden="true" />}
                      {copy.download}
                    </Button>
                  </article>
                );
              })}
            </div>
          </div>
        ) : null}

        {records.length === 0 ? (
          <div className="mt-8 rounded-lg border border-dashed border-[#d3aab2] bg-white/62 p-8 text-center dark:border-white/18 dark:bg-white/6">
            <Film className="mx-auto size-9 text-[#b94e70]" aria-hidden="true" />
            <h2 className="mt-4 text-xl font-semibold">{copy.emptyTitle}</h2>
            <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[#6d5960] dark:text-white/62">
              {copy.emptyBody}
            </p>
          </div>
        ) : (
          <div className="mt-8 grid gap-4 md:grid-cols-2">
            {records.map((record) => {
              const hasLocalFile = hasSavedLocalGalleryFile(record);
              return (
              <article key={record.id} className="overflow-hidden rounded-lg border border-[#e5c1c7] bg-white/70 dark:border-white/12 dark:bg-white/6">
                {hasLocalFile ? (
                  <video className="aspect-[9/16] w-full bg-[#20242e] object-contain" src={record.objectUrl} controls preload="metadata" />
                ) : (
                  <div className="flex aspect-[9/16] w-full flex-col items-center justify-center gap-3 bg-[#20242e] p-5 text-center text-white">
                    <Film className="size-9 text-[#ffd4dd]" aria-hidden="true" />
                    <p className="max-w-56 text-sm leading-6">{copy.localFileMissing}</p>
                  </div>
                )}
                <div className="p-4">
                  {renamingId === record.id ? (
                    <div className="flex gap-2">
                      <Input className="h-9 bg-white" value={draftTitle} onChange={(event) => setDraftTitle(event.target.value)} />
                      <Button type="button" size="sm" onClick={() => saveRename(record)}>{copy.save}</Button>
                    </div>
                  ) : (
                    <h2 className="font-semibold">{record.title}</h2>
                  )}
                  <p className="mt-1 text-xs text-[#6d5960] dark:text-white/62">{new Date(record.createdAt).toLocaleString()}</p>
                  <p className="mt-2 text-xs font-medium text-[#7c2947]">{hasLocalFile ? copy.savedOnDevice : copy.localFileMissingBadge}</p>
                  <div className="mt-4 flex flex-wrap items-center gap-2">
                    {hasLocalFile ? (
                      <Button asChild size="sm" className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]">
                        <a href={record.objectUrl} download={`${safeName(record.title)}.mp4`}>
                          <Download className="size-4" aria-hidden="true" />
                          {copy.download}
                        </a>
                      </Button>
                    ) : null}
                    <details className="relative">
                      <summary className="inline-flex h-9 w-9 cursor-pointer list-none items-center justify-center rounded-md border border-[#d7b0b8] bg-white/70 text-[#20242e] transition hover:bg-[#fff8f3] [&::-webkit-details-marker]:hidden dark:border-white/14 dark:bg-white/8 dark:text-white dark:hover:bg-white/12" aria-label={copy.rename}>
                        <MoreHorizontal className="size-4" aria-hidden="true" />
                      </summary>
                      <div className="absolute right-0 z-20 mt-2 grid min-w-40 gap-1 rounded-md border border-[#d7b0b8] bg-white p-1 shadow-lg dark:border-white/14 dark:bg-[#161b24]">
                        <button className="flex items-center gap-2 rounded px-3 py-2 text-left text-sm text-[#20242e] hover:bg-[#fff8f3] dark:text-white dark:hover:bg-white/8" type="button" onClick={() => startRename(record)}>
                          <Pencil className="size-4" aria-hidden="true" />
                          {copy.rename}
                        </button>
                        <button className="flex items-center gap-2 rounded px-3 py-2 text-left text-sm text-[#20242e] hover:bg-[#fff8f3] dark:text-white dark:hover:bg-white/8" type="button" onClick={() => deleteRecord(record)}>
                          <Trash2 className="size-4" aria-hidden="true" />
                          {copy.clearLocal}
                        </button>
                      </div>
                    </details>
                  </div>
                </div>
              </article>
            );
            })}
          </div>
        )}
      </Card>

      <Card className="gap-0 rounded-lg border-[#e5c1c7] bg-[#fff8f3]/88 p-5 text-[#20242e] shadow-sm shadow-[#7b233f]/6 dark:border-white/12 dark:bg-white/6 dark:text-white">
        <h2 className="text-lg font-semibold">{copy.availabilityTitle}</h2>
        <div className="mt-4 grid gap-3 text-sm leading-6 text-[#6d5960] dark:text-white/72">
          <p>{copy.availabilitySaved}</p>
          <p>{copy.availabilityRemote}</p>
          <p>{copy.availabilityPermanent}</p>
        </div>
      </Card>
    </section>
  );
}

function safeName(value: string) {
  return value.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "animate-av-video";
}
