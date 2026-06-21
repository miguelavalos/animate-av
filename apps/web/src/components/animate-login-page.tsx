import { ArrowRight, Film, Images, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { AvAppFooter, useAppsAvLocale } from "@avalsys/apps-av-web";
import { Button } from "@/components/ui/button";
import { animateBrandAssets } from "@/lib/animate-config";
import { localizedAppPath, useAnimateProductConfig, useAnimateText } from "@/lib/animate-i18n";

export function AnimateLoginPage({ comingSoon = false, compact = false }: { comingSoon?: boolean; compact?: boolean }) {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const productConfig = useAnimateProductConfig();
  const signInHref = localizedAppPath("/sign-in", locale);

  if (compact) {
    return (
      <div className="overflow-hidden rounded-lg border border-[#e5c1c7] bg-[#fff8f3]/90 shadow-lg shadow-[#7b233f]/10">
        <LoginContent comingSoon={comingSoon} locale={locale} signInHref={signInHref} text={text} />
      </div>
    );
  }

  return (
    <div className="animate-guest-shell min-h-screen overflow-hidden px-5 pt-5 sm:px-8">
      <LoginContent comingSoon={comingSoon} locale={locale} signInHref={signInHref} text={text} />
      <AvAppFooter className="mt-4 border-transparent bg-transparent px-0 pb-4 pt-2" labels={text.footer} product={productConfig} />
    </div>
  );
}

function LoginContent({ comingSoon, locale, signInHref, text }: { comingSoon: boolean; locale: ReturnType<typeof useAppsAvLocale>; signInHref: string; text: ReturnType<typeof useAnimateText> }) {
  if (comingSoon) {
    return (
      <main className="animate-guest-stage mx-auto min-h-[32rem] max-w-6xl overflow-hidden rounded-[1.75rem] border border-[#e5c1c7] shadow-2xl shadow-[#7b233f]/14">
        <img className="animate-guest-backdrop" src={animateBrandAssets.guestHomeMotion} alt="" />
        <div className="animate-guest-shade" />
        <div className="animate-coming-soon-copy relative z-10 flex min-h-[32rem] items-end p-6 sm:p-10">
          <div className="max-w-2xl pb-2">
            <img className="h-auto w-56 max-w-full sm:w-64" src={animateBrandAssets.logo} alt="Animate AV" />
            <p className="mt-8 text-sm font-semibold uppercase tracking-[0.18em] text-[#b94e70]">
              {comingSoonLabel(locale)}
            </p>
            <h1 className="mt-4 text-4xl font-semibold leading-tight text-[#112a55] sm:text-5xl">
              {text.login.heroTitle}
            </h1>
            <p className="mt-5 max-w-lg text-base leading-7 text-[#334766]">
              {text.login.heroBody}
            </p>
            <Button disabled className="mt-7 h-12 rounded-full bg-[#7c2947] px-5 text-white shadow-lg shadow-[#7c2947]/18 disabled:opacity-100">
              {comingSoonLabel(locale)}
            </Button>
          </div>
        </div>
      </main>
    );
  }

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
              {comingSoon ? (
                <Button disabled className="h-12 rounded-full bg-[#7c2947] px-5 text-white shadow-lg shadow-[#7c2947]/18 disabled:opacity-100">
                  {comingSoonLabel(locale)}
                </Button>
              ) : (
                <Button asChild className="h-12 rounded-full bg-[#7c2947] px-5 text-white shadow-lg shadow-[#7c2947]/18 hover:bg-[#963956]">
                  <a href={signInHref} onClick={(event) => {
                    event.preventDefault();
                    window.location.assign(signInHref);
                  }}>
                    {text.login.cta}
                    <ArrowRight className="size-4" aria-hidden="true" />
                  </a>
                </Button>
              )}
            </div>
          </div>

          <div className="grid gap-3 text-sm text-[#334766] sm:grid-cols-3">
            <LoginMetric icon={<Images className="size-4" aria-hidden="true" />} label={text.login.search} />
            <LoginMetric icon={<Sparkles className="size-4" aria-hidden="true" />} label={text.login.aviGuidance} />
            <LoginMetric icon={<Film className="size-4" aria-hidden="true" />} label={text.login.notebook} />
          </div>
        </section>

        <section className="animate-guest-gallery" aria-hidden="true">
          <img className="animate-guest-gallery-image" src={animateBrandAssets.guestHomeLooks} alt="" />
          <div className="animate-guest-note">
            <p className="font-serif text-2xl leading-tight text-[#20242e]">{text.login.mapTitle}</p>
            <p className="mt-2 text-sm leading-6 text-[#4d5563]">{text.login.mapBody}</p>
          </div>
        </section>
      </main>
  );
}

function comingSoonLabel(locale: ReturnType<typeof useAppsAvLocale>) {
  return ({ ca: "Properament", de: "Demnächst", en: "Coming soon", es: "Próximamente", fr: "Prochainement" } as const)[locale] ?? "Coming soon";
}

function LoginMetric({ icon, label }: { icon: ReactNode; label: string }) {
  return (
    <div className="flex min-h-12 items-center gap-2 rounded-xl border border-[#e5c1c7] bg-[#fff8f3]/72 px-3 shadow-sm shadow-[#7b233f]/5">
      <span className="text-[#b94e70]">{icon}</span>
      <span className="font-medium text-[#4d5563]">{label}</span>
    </div>
  );
}
