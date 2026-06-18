import { AuthLoading, SignedIn, SignedOut } from "@avalsys/account-av-web";
import { AuthSkeleton, AvAppFooter, useAppsAvLocale } from "@avalsys/apps-av-web";
import type { ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { animateBrandAssets } from "@/lib/animate-config";
import { localizedAppPath, useAnimateProductConfig, useAnimateText } from "@/lib/animate-i18n";

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const text = useAnimateText();
  const productConfig = useAnimateProductConfig();
  const locale = useAppsAvLocale();
  const signInHref = localizedAppPath("/sign-in", locale);

  return (
    <>
      <AuthLoading>
        <AuthSkeleton />
      </AuthLoading>
      <SignedIn>{children}</SignedIn>
      <SignedOut>
        <div className="animate-canvas flex min-h-screen flex-col">
          <main className="flex flex-1 items-center justify-center px-6 py-10 text-center">
            <div className="relative max-w-3xl overflow-hidden rounded-lg border border-border bg-card/88 p-8 pb-28 shadow-lg sm:p-10 sm:pb-10">
              <img className="mx-auto h-auto w-64" src={animateBrandAssets.logo} alt="Animate AV" />
              <h1 className="mt-8 text-4xl font-semibold text-foreground">{text.protected.title}</h1>
              <p className="mx-auto mt-4 max-w-xl text-base leading-7 text-muted-foreground">
                {text.protected.body}
              </p>
              <Button asChild className="mt-8 h-11 px-5">
                <a className="animate-visible-focus" href={signInHref}>{text.protected.cta}</a>
              </Button>
              <img className="absolute bottom-0 right-5 w-28 translate-y-6 sm:hidden" src={animateBrandAssets.aviFullBody} alt="Avi" />
            </div>
          </main>
          <AvAppFooter className="border-transparent bg-transparent" labels={text.footer} product={productConfig} />
        </div>
      </SignedOut>
    </>
  );
}
