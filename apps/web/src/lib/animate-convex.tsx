import { useAccountSession } from "@avalsys/account-av-web";
import { ConvexProvider, ConvexReactClient, useQueries } from "convex/react";
import { makeFunctionReference } from "convex/server";
import type { FunctionReference } from "convex/server";
import type { ReactNode } from "react";
import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { getAnimateConvexUrl } from "@/lib/animate-config";
import { useAnimateApiClient } from "@/lib/animate-client-hooks";
import { localizedAnimateErrorMessage } from "@/lib/animate-errors";
import { useAnimateText } from "@/lib/animate-i18n";
import type { AnimateArtifact, AnimateVideoJob } from "@/lib/animate-models";

const convexUrl = getAnimateConvexUrl();

const listVideoJobs = makeFunctionReference<"query", { ownerUserId: string; realtimeSessionId: string }, AnimateVideoJob[]>("animate:listVideoJobs");
const listImageJobs = makeFunctionReference<"query", { ownerUserId: string; realtimeSessionId: string }, AnimateVideoJob[]>("animate:listImageJobs");
const listGalleryArtifacts = makeFunctionReference<"query", { ownerUserId: string; realtimeSessionId: string }, AnimateArtifact[]>("animate:listGalleryArtifacts");

interface RealtimeSessionContextValue {
  realtimeSessionId: string | null;
  isConfigured: boolean;
  isLoading: boolean;
  errorMessage: string | null;
}

const RealtimeSessionContext = createContext<RealtimeSessionContextValue>({
  realtimeSessionId: null,
  isConfigured: Boolean(convexUrl),
  isLoading: false,
  errorMessage: null
});

export function AnimateConvexProvider({ children }: { children: ReactNode }) {
  const client = useMemo(() => convexUrl ? new ConvexReactClient(convexUrl) : null, []);
  if (!client) {
    return <>{children}</>;
  }

  return <ConvexProvider client={client}>{children}</ConvexProvider>;
}

export function AnimateRealtimeSessionProvider({ children }: { children: ReactNode }) {
  const api = useAnimateApiClient();
  const session = useAccountSession();
  const text = useAnimateText();
  const [realtimeSessionId, setRealtimeSessionId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setRealtimeSessionId(null);
    setErrorMessage(null);
    if (!convexUrl || !session.isLoaded || !session.isSignedIn) {
      return;
    }

    setIsLoading(true);
    api.createRealtimeSession()
      .then((response) => {
        if (!cancelled) {
          setRealtimeSessionId(response.realtimeSessionId);
        }
      })
      .catch((error: unknown) => {
        if (!cancelled) {
          setErrorMessage(localizedAnimateErrorMessage(error, text.errors));
        }
      })
      .finally(() => {
        if (!cancelled) {
          setIsLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [api, session.isLoaded, session.isSignedIn, session.userId, text.errors]);

  const value = useMemo(() => ({
    realtimeSessionId,
    isConfigured: Boolean(convexUrl),
    isLoading,
    errorMessage
  }), [errorMessage, isLoading, realtimeSessionId]);

  return <RealtimeSessionContext.Provider value={value}>{children}</RealtimeSessionContext.Provider>;
}

export function useAnimateRealtimeStatus() {
  return useContext(RealtimeSessionContext);
}

export function useAnimateInProgressJobs() {
  const session = useAccountSession();
  const realtime = useAnimateRealtimeStatus();
  if (!convexUrl) {
    return {
      jobs: [],
      isConfigured: false,
      isLoading: false,
      errorMessage: null
    };
  }
  const canSubscribe = Boolean(convexUrl && session.userId && realtime.realtimeSessionId);
  const ownerUserId = session.userId ?? "";
  const realtimeSessionId = realtime.realtimeSessionId ?? "";
  const queries = useQueries(canSubscribe ? {
    videoJobs: {
      query: listVideoJobs as FunctionReference<"query">,
      args: { ownerUserId, realtimeSessionId }
    },
    imageJobs: {
      query: listImageJobs as FunctionReference<"query">,
      args: { ownerUserId, realtimeSessionId }
    }
  } : {});

  return {
    jobs: [
      ...((queries.videoJobs ?? []) as AnimateVideoJob[]).map((job) => ({ ...job, assetKind: "video" as const })),
      ...((queries.imageJobs ?? []) as AnimateVideoJob[]).map((job) => ({ ...job, assetKind: "image" as const }))
    ].sort((left, right) => right.updatedAt - left.updatedAt),
    isConfigured: realtime.isConfigured,
    isLoading: realtime.isLoading || (canSubscribe && (queries.videoJobs === undefined || queries.imageJobs === undefined)),
    errorMessage: realtime.errorMessage
  };
}

export function useAnimateGalleryArtifacts() {
  const session = useAccountSession();
  const realtime = useAnimateRealtimeStatus();
  if (!convexUrl) {
    return {
      artifacts: [],
      isConfigured: false,
      isLoading: false,
      errorMessage: null
    };
  }
  const canSubscribe = Boolean(convexUrl && session.userId && realtime.realtimeSessionId);
  const ownerUserId = session.userId ?? "";
  const realtimeSessionId = realtime.realtimeSessionId ?? "";
  const queries = useQueries(canSubscribe ? {
    artifacts: {
      query: listGalleryArtifacts as FunctionReference<"query">,
      args: { ownerUserId, realtimeSessionId }
    }
  } : {});

  return {
    artifacts: (queries.artifacts ?? []) as AnimateArtifact[],
    isConfigured: realtime.isConfigured,
    isLoading: realtime.isLoading || (canSubscribe && queries.artifacts === undefined),
    errorMessage: realtime.errorMessage
  };
}
