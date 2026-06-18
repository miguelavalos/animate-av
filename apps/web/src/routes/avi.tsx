import { AccountUserButton, useAccountSession } from "@avalsys/account-av-web";
import { AppShell, useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { CreditCard, Film, Images, ListVideo, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { useEffect, useMemo, useState } from "react";
import { ProtectedRoute } from "@/components/protected-route";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useAnimateApiClient } from "@/lib/animate-client-hooks";
import { loadGalleryRecords, loadLocalInProgressJobs, subscribeGalleryRecords, subscribeLocalInProgressJobs } from "@/lib/animate-browser-utils";
import { useAnimateInProgressJobs } from "@/lib/animate-convex";
import { mergeInProgressJobs } from "@/lib/animate-in-progress-state";
import type { AnimateLocalInProgressJob } from "@/lib/animate-models";
import { spendableCredits } from "@/lib/animate-render-state";
import { localizedAppPath, useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/avi")({
  component: AviRoute
});

function AviRoute() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();

  return (
    <ProtectedRoute>
      <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
        <AviSurface locale={locale} />
      </AppShell>
    </ProtectedRoute>
  );
}

function AviSurface({ locale }: { locale: ReturnType<typeof useAppsAvLocale> }) {
  const text = useAnimateText();
  const api = useAnimateApiClient();
  const session = useAccountSession();
  const realtimeJobs = useAnimateInProgressJobs();
  const [localVideoCount, setLocalVideoCount] = useState(0);
  const [localJobs, setLocalJobs] = useState<AnimateLocalInProgressJob[]>([]);
  const balanceQuery = useQuery({
    enabled: Boolean(session.isLoaded && session.isSignedIn),
    queryKey: ["animate-av", "credits", "balance", session.userId],
    queryFn: () => api.getCreditBalance(),
    staleTime: 30_000
  });
  const creditCount = useMemo(() => spendableCredits(balanceQuery.data, balanceQuery.isFetched), [balanceQuery.data, balanceQuery.isFetched]);

  useEffect(() => {
    const refreshLocalVideoCount = () => setLocalVideoCount(loadGalleryRecords().length);
    const unsubscribe = subscribeGalleryRecords(refreshLocalVideoCount);
    refreshLocalVideoCount();
    return unsubscribe;
  }, []);

  useEffect(() => {
    const refreshLocalJobs = () => setLocalJobs(loadLocalInProgressJobs());
    const unsubscribe = subscribeLocalInProgressJobs(refreshLocalJobs);
    refreshLocalJobs();
    return unsubscribe;
  }, []);

  const activeJobs = useMemo(() => mergeInProgressJobs(realtimeJobs.jobs, localJobs), [localJobs, realtimeJobs.jobs]);
  const creditMessage = creditCount === null
    ? text.avi.creditLoading
    : creditCount > 0
      ? `${creditCount} ${creditCount === 1 ? text.avi.creditAvailable : text.avi.creditAvailablePlural}`
      : text.avi.creditNone;
  const activeWorkMessage = realtimeJobs.isLoading
    ? text.avi.activeWorkLoading
    : activeJobs.length === 0
      ? text.avi.activeWorkNone
      : activeJobs.length === 1
        ? text.avi.activeWorkOne
        : `${activeJobs.length} ${text.avi.activeWorkMany}`;
  const localVideosMessage = `${localVideoCount} ${localVideoCount === 1 ? text.avi.localVideoSaved : text.avi.localVideoSavedPlural}`;
  const createCard = text.avi.cards[0] ?? { title: text.avi.createCta, text: text.avi.body };

  return (
    <section className="grid gap-6 lg:grid-cols-[1.05fr_0.95fr]">
      <Card className="animate-canvas gap-0 overflow-hidden rounded-lg border-[#e5c1c7] p-0 text-[#20242e] shadow-lg shadow-[#7b233f]/8 dark:border-white/12 dark:text-white">
        <div className="grid min-h-[32rem] lg:grid-cols-[0.95fr_1.05fr]">
          <div className="flex flex-col justify-between gap-8 p-6">
            <div>
              <p className="flex items-center gap-2 text-sm font-semibold text-[#b94e70]">
                <Sparkles className="size-4" aria-hidden="true" />
                Avi
              </p>
              <h1 className="mt-3 text-3xl font-semibold leading-tight">{text.avi.heroTitle}</h1>
              <p className="mt-4 text-sm leading-6 text-[#4d5563] dark:text-white/72">
                {text.avi.heroBody}
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-3">
              <Button asChild className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]">
                <a href={localizedAppPath("/create", locale)}>
                  <Images className="size-4" aria-hidden="true" />
                  {text.avi.createCta}
                </a>
              </Button>
              <Button asChild variant="ghost" className="rounded-md text-[#7c2947] hover:bg-[#fff8f3]/76 dark:text-[#f0a5ba] dark:hover:bg-white/8">
                <a href={localizedAppPath("/in-progress", locale)}>{text.avi.inProgressCta}</a>
              </Button>
            </div>
          </div>
          <div className="relative min-h-80 overflow-hidden bg-[#20242e]">
            <div className="absolute inset-0 bg-[linear-gradient(160deg,#5e3041_0%,#20242e_56%,#11151d_100%)]" />
            <img className="relative h-full w-full object-cover object-bottom" src="/assets/avi-login-sheet-peek.png" alt="" />
          </div>
        </div>
      </Card>

      <div className="grid gap-4">
        <AviCard icon={<Images className="size-4" />} title={createCard.title} text={createCard.text} />
        <AviCard icon={<CreditCard className="size-4" />} title={text.avi.creditsTitle} text={creditMessage} />
        <AviCard icon={<ListVideo className="size-4" />} title={text.avi.activeWorkTitle} text={activeWorkMessage} />
        <AviCard icon={<Film className="size-4" />} title={text.avi.localVideosTitle} text={localVideosMessage} />
      </div>
    </section>
  );
}

function AviCard({ icon, text, title }: { icon: ReactNode; text: string; title: string }) {
  return (
    <Card className="gap-2 rounded-lg border-[#e5c1c7] bg-[#fff8f3]/88 p-5 text-[#20242e] shadow-sm shadow-[#7b233f]/6 dark:border-white/12 dark:bg-white/6 dark:text-white">
      <div className="flex items-center gap-2 text-sm font-semibold">
        <span className="text-[#b94e70]">{icon}</span>
        {title}
      </div>
      <p className="text-sm leading-6 text-[#6d5960] dark:text-white/72">{text}</p>
    </Card>
  );
}
