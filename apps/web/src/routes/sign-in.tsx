import { AccountSignIn, SignedIn, SignedOut } from "@avalsys/account-av-web";
import { AvAppFooter, useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { ArrowLeft } from "lucide-react";
import { animateBrandAssets } from "@/lib/animate-config";
import { localizedAppPath, useAnimateProductConfig, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/sign-in")({
  component: SignInRoute
});

function SignInRoute() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const productConfig = useAnimateProductConfig();

  return (
    <div className="animate-canvas flex min-h-screen flex-col bg-[#fbf7f2]">
      <main className="grid flex-1 lg:grid-cols-[0.92fr_1.08fr]">
        <section className="relative hidden min-h-screen overflow-hidden bg-[#20242e] p-10 text-white lg:flex lg:flex-col lg:justify-between">
          <div className="absolute inset-0 bg-[linear-gradient(160deg,#5e3041_0%,#20242e_54%,#11151d_100%)]" />
          <a className="relative inline-flex items-center gap-2 text-sm font-medium text-white/76 transition hover:text-white" href={localizedAppPath("/", locale)}>
            <ArrowLeft className="size-4" aria-hidden="true" />
            Animate AV
          </a>
          <div className="relative max-w-md">
            <img className="mb-10 h-auto w-64 brightness-0 invert" src={animateBrandAssets.logo} alt="Animate AV" />
            <h1 className="text-4xl font-semibold leading-tight">{text.signIn.title}</h1>
            <p className="mt-5 text-base leading-7 text-white/70">
              {text.signIn.body}
            </p>
          </div>
          <div className="relative overflow-hidden rounded-[1.5rem] border border-white/12 bg-[#fbf7f2] p-5 pb-0 text-[#20242e] shadow-2xl shadow-black/22">
            <div className="relative z-10 max-w-xs pb-28">
              <p className="text-sm font-semibold text-[#b94e70]">Avi</p>
              <p className="mt-2 font-serif text-3xl leading-tight">{text.signIn.aviPanelBody}</p>
            </div>
            <img
              className="absolute bottom-0 right-6 w-52 translate-y-8 drop-shadow-2xl"
              src={animateBrandAssets.aviLoginSheetPeek}
              alt="Avi"
            />
          </div>
        </section>

        <section className="flex min-h-screen items-center justify-center px-5 py-10">
          <div className="w-full max-w-md rounded-[1.5rem] border border-[#e5c1c7] bg-white/72 p-4 shadow-2xl shadow-[#7b233f]/10 backdrop-blur sm:p-6">
            <a className="mb-8 inline-flex items-center gap-2 text-sm font-medium text-[#6d5960] transition hover:text-[#20242e] lg:hidden" href={localizedAppPath("/", locale)}>
              <ArrowLeft className="size-4" aria-hidden="true" />
              Animate AV
            </a>
            <img className="mb-8 h-auto w-64 lg:hidden" src={animateBrandAssets.logo} alt="Animate AV" />
            <div className="mb-5 flex items-center gap-3 rounded-2xl border border-[#e5c1c7] bg-[#fff8f3]/82 p-3 shadow-sm shadow-[#7b233f]/8 lg:hidden">
              <img className="h-16 w-16 object-contain" src={animateBrandAssets.aviFullBody} alt="Avi" />
              <p className="text-sm font-medium leading-5 text-[#4d5563]">{text.signIn.aviPanelBody}</p>
            </div>
            <SignedIn>
              <div className="rounded-2xl border border-[#e5c1c7] bg-[#fff8f3] p-6 text-center shadow-lg shadow-[#7b233f]/10">
                <p className="text-sm font-semibold text-[#20242e]">{text.signIn.signedIn}</p>
                <a className="mt-4 inline-flex h-10 items-center justify-center rounded-full bg-[#7c2947] px-4 text-sm font-semibold text-white" href={localizedAppPath("/", locale)}>
                  {text.signIn.continue}
                </a>
              </div>
            </SignedIn>
            <SignedOut>
              <AccountSignIn fallbackRedirectUrl={localizedAppPath("/", locale)} path="/sign-in" />
            </SignedOut>
          </div>
        </section>
      </main>
      <AvAppFooter labels={text.footer} product={productConfig} />
    </div>
  );
}
