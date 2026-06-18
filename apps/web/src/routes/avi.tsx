import { AccountUserButton } from "@avalsys/account-av-web";
import { AppShell, useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { Film, Images, SlidersHorizontal, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { ProtectedRoute } from "@/components/protected-route";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { animateBrandAssets } from "@/lib/animate-config";
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
  const cardIcons = [<Images className="size-4" />, <SlidersHorizontal className="size-4" />, <Film className="size-4" />];

  return (
    <ProtectedRoute>
      <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
        <section className="grid gap-6 lg:grid-cols-[1.05fr_0.95fr]">
          <Card className="animate-canvas gap-0 overflow-hidden rounded-[1.5rem] border-[#e5c1c7] p-0 text-[#20242e] shadow-lg shadow-[#7b233f]/8">
            <div className="grid min-h-[32rem] lg:grid-cols-[0.95fr_1.05fr]">
              <div className="flex flex-col justify-between gap-8 p-6 sm:p-8">
                <div>
                  <p className="flex items-center gap-2 text-sm font-semibold text-[#b94e70]">
                    <Sparkles className="size-4" aria-hidden="true" />
                    Avi
                  </p>
                  <h1 className="mt-3 text-4xl font-semibold leading-tight">{text.avi.title}</h1>
                  <p className="mt-4 text-base leading-7 text-[#4d5563]">
                    {text.avi.body}
                  </p>
                </div>
                <div className="flex flex-wrap gap-3">
                  <Button asChild className="rounded-full bg-[#7c2947] text-white hover:bg-[#963956]">
                    <a href={localizedAppPath("/create", locale)}>
                      <Images className="size-4" aria-hidden="true" />
                      {text.avi.createCta}
                    </a>
                  </Button>
                  <Button asChild variant="outline" className="rounded-full border-[#e5c1c7] bg-[#fff8f3]/76">
                    <a href={localizedAppPath("/gallery", locale)}>{text.avi.galleryCta}</a>
                  </Button>
                </div>
              </div>
              <div className="relative min-h-80 overflow-hidden bg-[#20242e]">
                <div className="absolute inset-0 bg-[linear-gradient(160deg,#5e3041_0%,#20242e_56%,#11151d_100%)]" />
                <img className="relative h-full w-full object-cover object-bottom" src={animateBrandAssets.aviLoginPeek} alt="" />
              </div>
            </div>
          </Card>

          <div className="grid gap-4">
            {text.avi.cards.map((card, index) => (
              <AviCard key={card.title} icon={cardIcons[index]} title={card.title} text={card.text} />
            ))}
          </div>
        </section>
      </AppShell>
    </ProtectedRoute>
  );
}

function AviCard({ icon, text, title }: { icon: ReactNode; text: string; title: string }) {
  return (
    <Card className="gap-2 rounded-[1.25rem] border-[#e5c1c7] bg-[#fff8f3]/88 p-5 py-5 text-[#20242e] shadow-sm shadow-[#7b233f]/6">
      <div className="flex items-center gap-2 text-sm font-semibold">
        <span className="text-[#b94e70]">{icon}</span>
        {title}
      </div>
      <p className="text-sm leading-6 text-[#6d5960]">{text}</p>
    </Card>
  );
}
