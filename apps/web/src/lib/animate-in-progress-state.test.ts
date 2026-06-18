import { describe, expect, test } from "bun:test";
import { mergeInProgressJobs } from "./animate-in-progress-state";
import type { AnimateLocalInProgressJob, AnimateVideoJob } from "./animate-models";

describe("Animate in-progress state", () => {
  test("merges realtime and local jobs instead of hiding local submitted work", () => {
    const jobs = mergeInProgressJobs(
      [realtimeJob({ id: "remote-1", title: "Remote", updatedAt: 10 })],
      [localJob({ id: "local-1", title: "Local", updatedAt: 20 })]
    );

    expect(jobs.map((job) => `${job.source}:${job.title}`)).toEqual(["local:Local", "realtime:Remote"]);
  });

  test("prefers realtime projection when it matches a local submitted job", () => {
    const jobs = mergeInProgressJobs(
      [realtimeJob({ id: "remote-1", title: "Projected", updatedAt: 30 })],
      [localJob({ id: "local-1", renderJobId: "remote-1", title: "Local pending", updatedAt: 20 })]
    );

    expect(jobs).toHaveLength(1);
    expect(jobs[0]?.source).toBe("realtime");
    expect(jobs[0]?.title).toBe("Projected");
  });

  test("matches realtime projections to local jobs by video and workflow references", () => {
    const jobs = mergeInProgressJobs(
      [realtimeJob({ id: "remote-1", videoId: "video-1", workflowRunId: "workflow-1", title: "Recovered", updatedAt: 40 })],
      [
        localJob({ id: "local-1", videoId: "video-1", title: "Local by video", updatedAt: 30 }),
        localJob({ id: "local-2", workflowRunId: "workflow-1", title: "Local by workflow", updatedAt: 20 })
      ]
    );

    expect(jobs).toHaveLength(1);
    expect(jobs[0]?.source).toBe("realtime");
    expect(jobs[0]?.title).toBe("Recovered");
  });
});

function realtimeJob(overrides: Partial<AnimateVideoJob>): AnimateVideoJob {
  return {
    id: "remote",
    title: "Remote job",
    status: "queued",
    updatedAt: 1,
    ...overrides
  };
}

function localJob(overrides: Partial<AnimateLocalInProgressJob>): AnimateLocalInProgressJob {
  return {
    id: "local",
    videoId: "video-local",
    title: "Local job",
    status: "queued",
    phase: "queued",
    createdAt: 1,
    updatedAt: 1,
    ...overrides
  };
}
