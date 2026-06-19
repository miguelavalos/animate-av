import { AccountAvProvider } from "@avalsys/account-av-web";
import { AppsAvWebProvider, getAppsAvLocaleFromSearch, useAppsAvLocale } from "@avalsys/apps-av-web";
import { HeadContent, Outlet, Scripts, createRootRoute, useRouterState } from "@tanstack/react-router";
import type { ReactNode } from "react";
import { getAccountApiBaseUrl, getAccountPublishableKey } from "@/lib/animate-config";
import { AnimateConvexProvider, AnimateRealtimeSessionProvider } from "@/lib/animate-convex";
import { localizedAppPath, useAnimateAccountLocalization, useAnimateText } from "@/lib/animate-i18n";
import "../styles.css";

const faviconUrl = "https://cdn.avalsys.com/apps-av/animate-av/favicon-32x32.png?v=20260619b";
const appleTouchIconUrl = "https://cdn.avalsys.com/apps-av/animate-av/apple-touch-icon.png?v=20260619b";

export const Route = createRootRoute({
  component: RootComponent,
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "Animate AV" }
    ],
    links: [
      { rel: "icon", type: "image/png", sizes: "32x32", href: faviconUrl },
      { rel: "apple-touch-icon", href: appleTouchIconUrl }
    ]
  })
});

function RootComponent() {
  return (
    <RootDocument>
      <Outlet />
    </RootDocument>
  );
}

function RootDocument({ children }: Readonly<{ children: ReactNode }>) {
  const search = useRouterState({ select: (state) => state.location.searchStr });
  const initialLocale = getAppsAvLocaleFromSearch(search);

  return (
    <html lang={initialLocale}>
      <head>
        <HeadContent />
      </head>
      <body>
        <AppsAvWebProvider initialLocale={initialLocale}>
          <AccountBoundary>{children}</AccountBoundary>
        </AppsAvWebProvider>
        <Scripts />
      </body>
    </html>
  );
}

function AccountBoundary({ children }: Readonly<{ children: ReactNode }>) {
  const publishableKey = getAccountPublishableKey();
  const locale = useAppsAvLocale();
  const localization = useAnimateAccountLocalization();

  if (!publishableKey) {
    return <MissingAuthConfiguration />;
  }

  return (
      <AccountAvProvider
        accountApiBaseUrl={getAccountApiBaseUrl()}
        afterSignOutUrl={localizedAppPath("/", locale)}
      appDisplayName="Animate AV"
      appId="animateav"
      localization={localization}
      publishableKey={publishableKey}
      signInUrl={localizedAppPath("/sign-in", locale)}
      signUpUrl={localizedAppPath("/sign-in", locale)}
    >
      <AnimateConvexProvider>
        <AnimateRealtimeSessionProvider>{children}</AnimateRealtimeSessionProvider>
      </AnimateConvexProvider>
    </AccountAvProvider>
  );
}

function MissingAuthConfiguration() {
  const text = useAnimateText();

  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center px-6">
      <div className="rounded-lg border bg-card p-6 text-card-foreground shadow-sm">
        <p className="text-sm font-semibold uppercase text-muted-foreground">{text.config.eyebrow}</p>
        <h1 className="mt-4 text-3xl font-semibold text-foreground">{text.config.title}</h1>
        <p className="mt-3 text-sm leading-6 text-muted-foreground">{text.config.body}</p>
      </div>
    </main>
  );
}
