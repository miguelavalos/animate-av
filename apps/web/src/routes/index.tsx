import { AccountUserButton, SignedIn, SignedOut } from "@avalsys/account-av-web";
import { AppShell, AvAppFooter, useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { ArrowRight, Film, Images, ListVideo, SlidersHorizontal, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { animateBrandAssets } from "@/lib/animate-config";
import { localizedAppPath, useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/")({
  component: IndexRoute
});

function IndexRoute() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();

  return (
    <>
      <SignedOut>
        <PublicHome locale={locale} />
      </SignedOut>
      <SignedIn>
        <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
          <SignedInHome locale={locale} />
        </AppShell>
      </SignedIn>
    </>
  );
}

function PublicHome({ locale }: { locale: ReturnType<typeof useAppsAvLocale> }) {
  const text = useAnimateText();
  const productConfig = useAnimateProductConfig();

  return (
    <div className="animate-canvas flex min-h-screen flex-col">
      <main className="mx-auto grid w-full max-w-6xl flex-1 gap-8 px-6 py-8 lg:grid-cols-[1fr_25rem] lg:items-center">
        <section>
          <img className="h-auto w-64" src={animateBrandAssets.logo} alt="Animate AV" />
          <h1 className="mt-8 max-w-3xl text-5xl font-semibold leading-tight text-[#20242e] dark:text-white">{text.home.title}</h1>
          <p className="mt-5 max-w-2xl text-base leading-7 text-[#4d5563] dark:text-white/72">
            {text.home.body}
          </p>
          <div className="mt-7 flex flex-wrap gap-3">
            <Button asChild className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]">
              <a href={localizedAppPath("/sign-in", locale)}>
                {text.login.cta}
                <ArrowRight className="size-4" aria-hidden="true" />
              </a>
            </Button>
            <Button asChild variant="outline" className="rounded-md border-[#e5c1c7] bg-white/70 dark:border-white/14 dark:bg-white/8 dark:text-white">
              <a href={localizedAppPath("/avi", locale)}>{text.nav.avi}</a>
            </Button>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-3">
            {text.home.items.map((item, index) => (
              <NotebookItem key={item.label} icon={[<Images className="size-4" />, <SlidersHorizontal className="size-4" />, <Film className="size-4" />][index]} label={item.label} value={item.value} />
            ))}
          </div>
        </section>
        <Card className="gap-0 overflow-hidden rounded-lg border-[#e5c1c7] bg-[#20242e] p-0 text-white shadow-lg shadow-[#7b233f]/14">
          <img className="h-[32rem] w-full object-cover object-bottom" src={animateBrandAssets.onboarding} alt="" />
        </Card>
      </main>
      <AvAppFooter className="border-transparent bg-transparent" labels={text.footer} product={productConfig} />
    </div>
  );
}

function SignedInHome({ locale }: { locale: ReturnType<typeof useAppsAvLocale> }) {
  const text = useAnimateText();
  const homeIcons = [<Images className="size-4" />, <SlidersHorizontal className="size-4" />, <Film className="size-4" />];

  return (
    <section className="grid gap-6 lg:grid-cols-[1fr_22rem]">
      <Card className="animate-canvas gap-0 overflow-hidden rounded-lg border-[#e5c1c7] p-6 py-6 shadow-lg shadow-[#7b233f]/8 dark:border-white/12">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h1 className="max-w-2xl text-4xl font-semibold leading-tight text-[#20242e] dark:text-white">{text.home.title}</h1>
            <p className="mt-4 max-w-2xl text-base leading-7 text-[#4d5563] dark:text-white/72">{text.home.body}</p>
          </div>
          <Button asChild className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]">
            <a href={localizedAppPath("/create", locale)}>
              {text.home.cta}
              <ArrowRight className="size-4" aria-hidden="true" />
            </a>
          </Button>
        </div>
        <div className="mt-8 grid gap-3 sm:grid-cols-3">
          {text.home.items.map((item, index) => (
            <NotebookItem key={item.label} icon={homeIcons[index]} label={item.label} value={item.value} />
          ))}
        </div>
      </Card>
      <Card className="gap-0 overflow-hidden rounded-lg border-[#e5c1c7] bg-[#20242e] p-5 text-white shadow-lg shadow-[#7b233f]/14">
        <div className="flex items-center gap-2 text-sm font-semibold text-[#f3b1bf]">
          <Sparkles className="size-4" aria-hidden="true" />
          {text.home.aviTitle}
        </div>
        <ul className="mt-4 flex flex-col gap-3 text-sm leading-6 text-white/74">
          {text.home.aviBody.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
        <div className="mt-6 grid gap-2">
          <Button asChild variant="outline" className="rounded-md border-white/20 bg-white/10 text-white hover:bg-white/15">
            <a href={localizedAppPath("/in-progress", locale)}>
              <ListVideo className="size-4" aria-hidden="true" />
              {text.nav.inProgress}
            </a>
          </Button>
          <Button asChild variant="outline" className="rounded-md border-white/20 bg-white/10 text-white hover:bg-white/15">
            <a href={localizedAppPath("/gallery", locale)}>{text.nav.gallery}</a>
          </Button>
        </div>
      </Card>
    </section>
  );
}

function NotebookItem({ icon, label, value }: { icon: ReactNode; label: string; value: string }) {
  return (
    <div className="rounded-lg border border-[#e5c1c7] bg-[#fff8f3]/76 p-4 text-[#20242e] dark:border-white/12 dark:bg-white/6 dark:text-white">
      <div className="flex items-center gap-2 text-sm font-semibold">
        <span className="text-[#b94e70]">{icon}</span>
        {label}
      </div>
      <p className="mt-2 text-sm text-[#6d5960] dark:text-white/62">{value}</p>
    </div>
  );
}
