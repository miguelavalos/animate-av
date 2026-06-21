import { ArrowRight, Film, Images, ListChecks, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { AvAppFooter, useAppsAvLocale } from "@avalsys/apps-av-web";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { animateBrandAssets } from "@/lib/animate-config";
import { localizedAppPath, useAnimateProductConfig, useAnimateText } from "@/lib/animate-i18n";

export function AnimateLoginPage({ compact = false }: { compact?: boolean }) {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const productConfig = useAnimateProductConfig();
  const signInHref = localizedAppPath("/sign-in", locale);

  if (compact) {
    return (
      <div className="overflow-hidden rounded-lg border border-[#e5c1c7] bg-[#fff8f3]/90 shadow-lg shadow-[#7b233f]/10">
        <LoginContent signInHref={signInHref} text={text} />
      </div>
    );
  }

  return (
    <div className="animate-guest-shell min-h-screen overflow-hidden px-5 pt-5 sm:px-8">
      <LoginContent signInHref={signInHref} text={text} />
      <AvAppFooter className="mt-4 border-transparent bg-transparent px-0 pb-4 pt-2" labels={text.footer} product={productConfig} />
    </div>
  );
}

function LoginContent({ signInHref, text }: { signInHref: string; text: ReturnType<typeof useAnimateText> }) {
  const guestScenes = [
    {
      body: text.login.mapBody,
      src: animateBrandAssets.guestHomeLooks,
      title: text.login.mapTitle
    },
    {
      body: text.login.cardBody,
      src: animateBrandAssets.guestHomeReview,
      title: text.login.cardTitle
    }
  ];

  return (
      <main className="animate-guest-stage mx-auto min-h-[32rem] max-w-6xl overflow-hidden rounded-[1.75rem] border border-[#e5c1c7] shadow-2xl shadow-[#7b233f]/14">
        <img className="animate-guest-backdrop" src={animateBrandAssets.guestHomeMotion} alt="" />
        <div className="animate-guest-shade" />
        <section className="animate-guest-copy">
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
                <a href={signInHref} onClick={(event) => {
                  event.preventDefault();
                  window.location.assign(signInHref);
                }}>
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

        <section className="animate-guest-gallery" aria-hidden="true">
          {guestScenes.map((scene, index) => (
            <article className={`animate-guest-scene animate-guest-scene-${index + 1}`} key={scene.src}>
              <img src={scene.src} alt="" />
              <div>
                <p className="font-serif text-2xl leading-tight text-[#20242e]">{scene.title}</p>
                <p className="mt-2 text-sm leading-6 text-[#4d5563]">{scene.body}</p>
              </div>
            </article>
          ))}
          <Card className="animate-guest-note relative gap-2 rounded-2xl border-[#e5c1c7] bg-[#fff8f3]/92 p-5 py-5 text-[#20242e] shadow-xl shadow-[#7c2947]/12">
            <p className="flex items-center gap-2 text-sm font-semibold">
              <ListChecks className="size-4 text-[#b94e70]" aria-hidden="true" />
              {text.login.cardTitle}
            </p>
            <p className="mt-2 text-sm leading-6 text-[#47566f]">
              {text.login.cardBody}
            </p>
          </Card>
        </section>
      </main>
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
