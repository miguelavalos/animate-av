import type { AnimateLocalInProgressJob, AnimateVideoJob } from "@/lib/animate-models";

export type AnimateActiveJob = (AnimateVideoJob | AnimateLocalInProgressJob) & { source: "realtime" | "local" };

export function mergeInProgressJobs(realtimeJobs: AnimateVideoJob[], localJobs: AnimateLocalInProgressJob[]) {
  const merged: AnimateActiveJob[] = [];
  const seen = new Set<string>();

  for (const job of realtimeJobs) {
    rememberJob(job, seen);
    merged.push({ ...job, source: "realtime" });
  }

  for (const job of localJobs) {
    if (jobKeys(job).some((key) => seen.has(key))) {
      continue;
    }
    rememberJob(job, seen);
    merged.push({ ...job, source: "local" });
  }

  return merged.sort((left, right) => right.updatedAt - left.updatedAt);
}

function rememberJob(job: AnimateVideoJob | AnimateLocalInProgressJob, seen: Set<string>) {
  for (const key of jobKeys(job)) {
    seen.add(key);
  }
}

function jobKeys(job: AnimateVideoJob | AnimateLocalInProgressJob) {
  const values = [
    job.id,
    "videoId" in job ? job.videoId : undefined,
    "renderJobId" in job ? job.renderJobId : undefined,
    "workflowRunId" in job ? job.workflowRunId : undefined
  ];
  return [
    key("id", job.id),
    key("video", "videoId" in job ? job.videoId : undefined),
    key("render", "renderJobId" in job ? job.renderJobId : undefined),
    key("workflow", "workflowRunId" in job ? job.workflowRunId : undefined),
    ...values.map((value) => key("any", value))
  ].filter(isPresent);
}

function key(prefix: string, value: string | undefined | null) {
  return value ? `${prefix}:${value}` : null;
}

function isPresent(value: string | null): value is string {
  return value !== null;
}
