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
          <img className="absolute inset-0 h-full w-full object-cover object-center opacity-58" src={animateBrandAssets.guestHomeReview} alt="" />
          <div className="absolute inset-0 bg-[linear-gradient(160deg,rgb(94_48_65/0.95)_0%,rgb(32_36_46/0.84)_50%,rgb(17_21_29/0.74)_100%)]" />
          <a className="animate-visible-focus relative inline-flex items-center gap-2 rounded-sm text-sm font-medium text-white/76 outline-none transition hover:text-white" href={localizedAppPath("/", locale)}>
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
          <div className="relative overflow-hidden rounded-[1.5rem] border border-white/12 bg-[#fbf7f2]/92 p-5 pb-0 text-[#20242e] shadow-2xl shadow-black/22 backdrop-blur">
            <div className="relative z-10 max-w-xs pb-28">
              <p className="text-sm font-semibold text-[#9b3658] dark:text-[#f0a5ba]">Avi</p>
              <p className="mt-2 font-serif text-3xl leading-tight">{text.signIn.aviPanelBody}</p>
            </div>
            <img
              className="absolute bottom-0 right-6 w-52 translate-y-8 drop-shadow-2xl"
              src={animateBrandAssets.aviLoginSheetPeek}
              alt="Avi"
            />
          </div>
        </section>

        <section className="flex min-h-screen min-w-0 items-center justify-center overflow-x-hidden px-4 py-10 sm:px-5">
          <div className="w-full max-w-[calc(100vw-2rem)] rounded-[1.5rem] border border-[#e5c1c7] bg-white/72 p-4 shadow-2xl shadow-[#7b233f]/10 backdrop-blur sm:max-w-md sm:p-6 dark:border-white/12 dark:bg-white/8">
            <a className="animate-visible-focus mb-8 inline-flex items-center gap-2 rounded-sm text-sm font-medium text-[#6d5960] outline-none transition hover:text-[#20242e] lg:hidden dark:text-white/72 dark:hover:text-white" href={localizedAppPath("/", locale)}>
              <ArrowLeft className="size-4" aria-hidden="true" />
              Animate AV
            </a>
            <img className="mb-8 h-auto w-64 max-w-full lg:hidden" src={animateBrandAssets.logo} alt="Animate AV" />
            <div className="mb-5 flex min-w-0 items-center gap-3 rounded-2xl border border-[#e5c1c7] bg-[#fff8f3]/82 p-3 shadow-sm shadow-[#7b233f]/8 lg:hidden dark:border-white/12 dark:bg-white/6">
              <img className="h-16 w-16 object-contain" src={animateBrandAssets.aviFullBody} alt="Avi" />
              <p className="min-w-0 text-sm font-medium leading-5 text-[#4d5563] dark:text-white/72">{text.signIn.aviPanelBody}</p>
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
              <div className="min-h-[31rem]">
                <AccountSignIn
                  appearance={{
                    elements: {
                      card: "shadow-none border-0 bg-transparent",
                      footerActionLink: "outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7c2947]",
                      formButtonPrimary: "outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7c2947]",
                      formFieldInput: "outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7c2947]",
                      headerSubtitle: "text-[#4d5563]",
                      headerTitle: "text-[#20242e]",
                      rootBox: "w-full",
                      socialButtonsBlockButton: "outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7c2947]",
                      socialButtonsProviderIcon: "aria-hidden"
                    }
                  }}
                  fallbackRedirectUrl={localizedAppPath("/", locale)}
                  path="/sign-in"
                />
              </div>
            </SignedOut>
          </div>
        </section>
      </main>
      <AvAppFooter labels={text.footer} product={productConfig} />
    </div>
  );
}
