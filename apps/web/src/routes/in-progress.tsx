import { AccountUserButton } from "@avalsys/account-av-web";
import { AppShell, useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { Activity, Film, Images, Loader2, MoreHorizontal, Pencil, RefreshCw, Trash2 } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { ProtectedRoute } from "@/components/protected-route";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { useAnimateApiClient } from "@/lib/animate-client-hooks";
import { deleteLocalInProgressJob, deleteLocalInProgressJobsByReference, loadLocalInProgressJobs, subscribeLocalInProgressJobs } from "@/lib/animate-browser-utils";
import { useAnimateInProgressJobs, useAnimateRealtimeStatus } from "@/lib/animate-convex";
import { localizedAnimateErrorMessage } from "@/lib/animate-errors";
import { mergeInProgressJobs, type AnimateActiveJob } from "@/lib/animate-in-progress-state";
import type { AnimateLocalInProgressJob, AnimateLook } from "@/lib/animate-models";
import { localizedAppPath, useAnimateLookCopy, useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/in-progress")({
  component: InProgressRoute
});

function InProgressRoute() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();
  const copy = text.inProgress;

  return (
    <ProtectedRoute>
      <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
        <InProgressSurface copy={copy} createHref={localizedAppPath("/create", locale)} errors={text.errors} galleryHref={localizedAppPath("/gallery", locale)} />
      </AppShell>
    </ProtectedRoute>
  );
}

function InProgressSurface({ copy, createHref, errors, galleryHref }: { copy: ReturnType<typeof useAnimateText>["inProgress"]; createHref: string; errors: ReturnType<typeof useAnimateText>["errors"]; galleryHref: string }) {
  const api = useAnimateApiClient();
  const lookCopy = useAnimateLookCopy();
  const realtime = useAnimateRealtimeStatus();
  const realtimeJobs = useAnimateInProgressJobs();
  const [localJobs, setLocalJobs] = useState<AnimateLocalInProgressJob[]>([]);
  const [renamingId, setRenamingId] = useState<string | null>(null);
  const [draftTitle, setDraftTitle] = useState("");
  const [busyJobId, setBusyJobId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLocalJobs(loadLocalInProgressJobs());
    return subscribeLocalInProgressJobs(() => setLocalJobs(loadLocalInProgressJobs()));
  }, []);

  const jobs = useMemo(() => mergeInProgressJobs(realtimeJobs.jobs, localJobs), [localJobs, realtimeJobs.jobs]);

  const counts = useMemo(() => ({
    queued: jobs.filter((job) => normalizedStatus(job.status) === "queued").length,
    running: jobs.filter((job) => ["running", "processing"].includes(normalizedStatus(job.status))).length,
    completed: jobs.filter((job) => ["completed", "available", "ready"].includes(normalizedStatus(job.status))).length
  }), [jobs]);

  function refreshLocal() {
    setLocalJobs(loadLocalInProgressJobs());
  }

  function startRename(job: AnimateActiveJob) {
    setRenamingId(job.id);
    setDraftTitle(job.title || copy.defaultTitle);
  }

  async function saveRename(job: AnimateActiveJob) {
    const nextTitle = draftTitle.trim();
    if (!nextTitle) {
      return;
    }
    setBusyJobId(job.id);
    setError(null);
    try {
      if (job.source === "realtime") {
        await api.renameVideoJob(job.id, nextTitle);
      }
      setRenamingId(null);
      setDraftTitle("");
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, errors));
    } finally {
      setBusyJobId(null);
    }
  }

  async function deleteJob(job: AnimateActiveJob) {
    setBusyJobId(job.id);
    setError(null);
    try {
      if (job.source === "realtime") {
        await api.deleteVideoJob(job.id);
        deleteLocalInProgressJobsByReference([job.id, job.videoId, job.renderJobId, job.workflowRunId]);
      } else {
        deleteLocalInProgressJob(job.id);
        refreshLocal();
      }
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, errors));
    } finally {
      setBusyJobId(null);
    }
  }

  return (
    <section className="grid gap-6 lg:grid-cols-[1fr_22rem]">
      <Card className="animate-canvas gap-0 rounded-lg border-[#e5c1c7] p-5 text-[#20242e] shadow-lg shadow-[#7b233f]/8 sm:p-6 dark:border-white/12 dark:text-white">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase text-[#b94e70]">{copy.badge}</p>
            <h1 className="mt-2 text-3xl font-semibold leading-tight">{copy.title}</h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-[#4d5563] dark:text-white/72">
              {copy.body}
            </p>
          </div>
          <Button asChild className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]">
            <a href={createHref}>
              <Images className="size-4" aria-hidden="true" />
              {copy.continueCreating}
            </a>
          </Button>
        </div>

        <div className="mt-8 grid gap-3 sm:grid-cols-3">
          <StatusCard icon={<Activity className="size-4" />} title={copy.queued} text={`${counts.queued} ${copy.waiting}`} />
          <StatusCard icon={<RefreshCw className="size-4" />} title={copy.running} text={`${counts.running} ${copy.rendering}`} />
          <StatusCard icon={<Film className="size-4" />} title={copy.completed} text={`${counts.completed} ${copy.ready}`} />
        </div>

        {error ? <p className="mt-5 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">{error}</p> : null}
        {realtimeJobs.errorMessage ? <p className="mt-5 rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-800">{realtimeJobs.errorMessage}</p> : null}

        {realtimeJobs.isLoading ? (
          <div className="mt-8 flex items-center gap-2 rounded-lg border border-[#e5c1c7] bg-white/62 p-5 text-sm font-semibold text-[#6d5960] dark:border-white/12 dark:bg-white/6 dark:text-white/72">
            <Loader2 className="size-4 animate-spin" aria-hidden="true" />
            {copy.loading}
          </div>
        ) : jobs.length === 0 ? (
          <div className="mt-8 rounded-lg border border-dashed border-[#d3aab2] bg-white/62 p-8 text-center dark:border-white/18 dark:bg-white/6">
            <Activity className="mx-auto size-9 text-[#b94e70]" aria-hidden="true" />
            <h2 className="mt-4 text-xl font-semibold">{copy.emptyTitle}</h2>
            <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[#6d5960] dark:text-white/62">
              {copy.emptyBody}
            </p>
          </div>
        ) : (
          <div className="mt-8 grid gap-3">
            {jobs.map((job) => (
              <article key={`${job.source}:${job.id}`} className="rounded-lg border border-[#e5c1c7] bg-white/70 p-4 dark:border-white/12 dark:bg-white/6">
                <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                  <div>
                    {renamingId === job.id ? (
                      <div className="flex max-w-md gap-2">
                        <Input className="h-9 bg-white" value={draftTitle} onChange={(event) => setDraftTitle(event.target.value)} />
                        <Button type="button" size="sm" disabled={busyJobId === job.id} onClick={() => void saveRename(job)}>{copy.save}</Button>
                      </div>
                    ) : (
                      <h2 className="font-semibold">{job.title || copy.defaultTitle}</h2>
                    )}
                    <p className="mt-1 text-sm text-[#6d5960] dark:text-white/62">
                      {jobStatusLabel(job.status, copy)}
                      {job.phase ? ` - ${jobPhaseLabel(job.phase, copy)}` : ""}
                      {assetKind(job) ? ` - ${assetKindLabel(assetKind(job), copy)}` : ""}
                    </p>
                    <p className="mt-1 text-xs text-[#6d5960] dark:text-white/62">
                      {job.look && job.look in lookCopy.titles ? lookCopy.titles[job.look as AnimateLook] : "Animate AV"} · {new Date(job.updatedAt).toLocaleString()}
                    </p>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    <Button asChild size="sm" variant="outline" className="rounded-md border-[#d7b0b8] bg-white/70 dark:border-white/14 dark:bg-white/8">
                      <a href={galleryHref}>{copy.videos}</a>
                    </Button>
                    <details className="relative">
                      <summary className="inline-flex h-9 w-9 cursor-pointer list-none items-center justify-center rounded-md border border-[#d7b0b8] bg-white/70 text-[#20242e] transition hover:bg-[#fff8f3] [&::-webkit-details-marker]:hidden dark:border-white/14 dark:bg-white/8 dark:text-white dark:hover:bg-white/12" aria-label={copy.delete}>
                        <MoreHorizontal className="size-4" aria-hidden="true" />
                      </summary>
                      <div className="absolute right-0 z-20 mt-2 grid min-w-40 gap-1 rounded-md border border-[#d7b0b8] bg-white p-1 shadow-lg dark:border-white/14 dark:bg-[#161b24]">
                        {job.source === "realtime" ? (
                          <button className="flex items-center gap-2 rounded px-3 py-2 text-left text-sm text-[#20242e] hover:bg-[#fff8f3] dark:text-white dark:hover:bg-white/8" type="button" onClick={() => startRename(job)}>
                            <Pencil className="size-4" aria-hidden="true" />
                            {copy.rename}
                          </button>
                        ) : null}
                        <button className="flex items-center gap-2 rounded px-3 py-2 text-left text-sm text-[#20242e] hover:bg-[#fff8f3] disabled:opacity-60 dark:text-white dark:hover:bg-white/8" type="button" disabled={busyJobId === job.id} onClick={() => void deleteJob(job)}>
                          {busyJobId === job.id ? <Loader2 className="size-4 animate-spin" aria-hidden="true" /> : <Trash2 className="size-4" aria-hidden="true" />}
                          {job.source === "realtime" ? copy.delete : copy.clearLocal}
                        </button>
                      </div>
                    </details>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </Card>
      <Card className="gap-0 rounded-lg border-[#e5c1c7] bg-[#fff8f3]/88 p-5 text-[#20242e] shadow-sm shadow-[#7b233f]/6 dark:border-white/12 dark:bg-white/6 dark:text-white">
        <h2 className="text-lg font-semibold">{copy.realtimeTitle}</h2>
        <div className="mt-4 grid gap-3 text-sm leading-6 text-[#6d5960] dark:text-white/72">
          <p>{realtime.isConfigured ? copy.realtimeConfigured : copy.realtimeNotConfigured}</p>
          <p>{realtime.realtimeSessionId ? copy.realtimeSessionActive : copy.realtimeSessionInactive}</p>
          <p>{copy.authority}</p>
        </div>
      </Card>
    </section>
  );
}

function StatusCard({ icon, text, title }: { icon: React.ReactNode; text: string; title: string }) {
  return (
    <div className="rounded-lg border border-[#e5c1c7] bg-white/62 p-4 dark:border-white/12 dark:bg-white/6">
      <div className="flex items-center gap-2 text-sm font-semibold text-[#20242e]">
        <span className="text-[#b94e70]">{icon}</span>
        {title}
      </div>
      <p className="mt-2 text-sm leading-6 text-[#6d5960] dark:text-white/62">{text}</p>
    </div>
  );
}

function normalizedStatus(status: string) {
  return status.toLowerCase();
}

function jobStatusLabel(status: string, copy: ReturnType<typeof useAnimateText>["inProgress"]) {
  const normalized = normalizedStatus(status);
  if (normalized === "queued") {
    return copy.queued;
  }
  if (["running", "processing"].includes(normalized)) {
    return copy.running;
  }
  if (["completed", "available", "ready"].includes(normalized)) {
    return copy.completed;
  }
  if (["failed", "error"].includes(normalized)) {
    return copy.failed;
  }
  if (["canceled", "cancelled"].includes(normalized)) {
    return copy.canceled;
  }
  return "Animate AV";
}

function jobPhaseLabel(phase: string, copy: ReturnType<typeof useAnimateText>["inProgress"]) {
  const normalized = normalizedStatus(phase).replace(/-/g, "_");
  if (["queued", "pending"].includes(normalized)) {
    return copy.queued;
  }
  if (["preparing_source", "generating_image", "animating_video", "composing_final", "processing", "running"].includes(normalized)) {
    return copy.rendering;
  }
  if (["completed", "available", "ready"].includes(normalized)) {
    return copy.ready;
  }
  if (["failed", "error"].includes(normalized)) {
    return copy.failed;
  }
  if (["canceled", "cancelled"].includes(normalized)) {
    return copy.canceled;
  }
  return "Animate AV";
}

function assetKindLabel(kind: string | null | undefined, copy: ReturnType<typeof useAnimateText>["inProgress"]) {
  if (!kind) {
    return null;
  }
  const normalized = normalizedStatus(kind).replace(/-/g, "_");
  if (normalized === "final_video") {
    return copy.finalVideo;
  }
  if (normalized === "source_image") {
    return copy.sourceImage;
  }
  return "Animate AV";
}

function assetKind(job: AnimateActiveJob) {
  return "assetKind" in job ? job.assetKind : null;
}
