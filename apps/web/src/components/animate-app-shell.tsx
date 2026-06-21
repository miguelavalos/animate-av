import { AccountUserButton } from "@avalsys/account-av-web";
import { AppShell } from "@avalsys/apps-av-web";
import { useRouterState } from "@tanstack/react-router";
import type { ReactNode } from "react";
import { useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export function AnimateAppShell({ children }: { children: ReactNode }) {
  const text = useAnimateText();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();
  const pathname = useRouterState({ select: (state) => state.location.pathname });

  return (
    <AppShell
      accountArea={<AccountUserButton />}
      currentPath={pathname}
      footerLabels={text.footer}
      labels={shellLabels}
      navLinks={navLinks}
      product={productConfig}
    >
      {children}
    </AppShell>
  );
}
