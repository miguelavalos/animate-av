import { ArrowRight, Film, Images, ListChecks, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { AvAppFooter, useAppsAvLocale } from "@avalsys/apps-av-web";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { animateBrandAssets } from "@/lib/animate-config";
import { localizedAppPath, useAnimateProductConfig, useAnimateText } from "@/lib/animate-i18n";

export function AnimateLoginPage() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const productConfig = useAnimateProductConfig();

  return (
    <div className="animate-canvas min-h-screen overflow-hidden px-5 pt-5 sm:px-8">
      <main className="mx-auto grid min-h-[calc(100vh-6rem)] max-w-6xl overflow-hidden rounded-[1.75rem] border border-[#e5c1c7] bg-[#fff8f3]/90 shadow-2xl shadow-[#7b233f]/14 backdrop-blur md:grid-cols-[0.95fr_1.05fr]">
        <section className="flex flex-col justify-between gap-10 p-7 sm:p-10 lg:p-12">
          <div>
            <img className="h-auto w-56 sm:w-64" src={animateBrandAssets.logo} alt="Animate AV" />
            <p className="mt-4 max-w-sm text-sm leading-6 text-[#314568]">
              {text.login.intro}
            </p>
          </div>

          <div className="max-w-xl">
            <h1 className="text-4xl font-semibold leading-[1.04] text-[#112a55] sm:text-5xl">
              {text.login.heroTitle}
            </h1>
            <p className="mt-6 max-w-lg text-base leading-7 text-[#334766]">
              {text.login.heroBody}
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Button asChild className="h-12 rounded-full bg-[#7c2947] px-5 text-white shadow-lg shadow-[#7c2947]/18 hover:bg-[#963956]">
                <a href={localizedAppPath("/sign-in", locale)}>
                  {text.login.cta}
                  <ArrowRight className="size-4" aria-hidden="true" />
                </a>
              </Button>
            </div>
          </div>

          <div className="grid gap-3 text-sm text-[#334766] sm:grid-cols-3">
            <LoginMetric icon={<Images className="size-4" aria-hidden="true" />} label={text.login.search} />
            <LoginMetric icon={<Sparkles className="size-4" aria-hidden="true" />} label={text.login.aviGuidance} />
            <LoginMetric icon={<Film className="size-4" aria-hidden="true" />} label={text.login.notebook} />
          </div>
        </section>

        <section className="relative min-h-[32rem] overflow-hidden bg-[#20242e] p-6 text-white lg:min-h-full">
          <div className="absolute inset-0 bg-[linear-gradient(160deg,#4c2736_0%,#20242e_52%,#11151d_100%)]" />
          <div className="relative flex h-full flex-col justify-between gap-6 overflow-hidden rounded-[1.4rem] border border-white/14 bg-[#fbf7f2] p-5 text-[#20242e] shadow-2xl shadow-black/24">
            <img className="absolute inset-y-0 right-0 h-full w-[60%] object-cover object-center opacity-90 sm:w-[58%]" src={animateBrandAssets.onboarding} alt="" />
            <div className="relative max-w-xs">
              <p className="font-serif text-3xl leading-tight text-[#20242e]">{text.login.mapTitle}</p>
              <p className="mt-4 text-sm leading-6 text-[#4d5563]">
                {text.login.mapBody}
              </p>
            </div>
            <Card className="relative mt-auto max-w-sm gap-2 rounded-2xl border-[#e5c1c7] bg-[#fff8f3]/90 p-5 py-5 text-[#20242e] shadow-xl shadow-[#7c2947]/12">
              <p className="flex items-center gap-2 text-sm font-semibold">
                <ListChecks className="size-4 text-[#b94e70]" aria-hidden="true" />
                {text.login.cardTitle}
              </p>
              <p className="mt-2 text-sm leading-6 text-[#47566f]">
                {text.login.cardBody}
              </p>
            </Card>
            <img
              className="absolute bottom-0 right-4 w-44 translate-y-8 drop-shadow-2xl sm:right-8 sm:w-52 lg:w-60"
              src={animateBrandAssets.aviLoginSheetPeek}
              alt="Avi"
            />
          </div>
        </section>
      </main>
      <AvAppFooter className="mt-4 border-transparent bg-transparent px-0 pb-4 pt-2" labels={text.footer} product={productConfig} />
    </div>
  );
}

function LoginMetric({ icon, label }: { icon: ReactNode; label: string }) {
  return (
    <div className="flex min-h-12 items-center gap-2 rounded-xl border border-[#e5c1c7] bg-[#fff8f3]/72 px-3 shadow-sm shadow-[#7b233f]/5">
      <span className="text-[#b94e70]">{icon}</span>
      <span className="font-medium text-[#4d5563]">{label}</span>
    </div>
  );
}
