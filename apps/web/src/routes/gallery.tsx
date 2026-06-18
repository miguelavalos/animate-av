import { AccountUserButton } from "@avalsys/account-av-web";
import { AppShell } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { Download, Film, History, PlayCircle } from "lucide-react";
import type { ReactNode } from "react";
import { ProtectedRoute } from "@/components/protected-route";
import { Card } from "@/components/ui/card";
import { useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/gallery")({
  component: GalleryRoute
});

function GalleryRoute() {
  const text = useAnimateText();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();
  const icons = [<PlayCircle className="size-4" />, <Download className="size-4" />, <History className="size-4" />];

  return (
    <ProtectedRoute>
      <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
        <section className="grid gap-6 lg:grid-cols-[1fr_22rem]">
          <Card className="animate-canvas gap-0 rounded-[1.5rem] border-[#e5c1c7] p-6 py-6 text-[#20242e] shadow-lg shadow-[#7b233f]/8 sm:p-8 sm:py-8">
            <p className="text-sm font-semibold uppercase text-[#b94e70]">{text.gallery.kicker}</p>
            <h1 className="mt-4 max-w-3xl text-4xl font-semibold leading-tight">{text.gallery.title}</h1>
            <p className="mt-4 max-w-2xl text-base leading-7 text-[#4d5563]">{text.gallery.body}</p>
            <div className="mt-8 flex flex-wrap gap-2">
              {text.gallery.filters.map((filter) => (
                <span key={filter} className="rounded-full border border-[#e5c1c7] bg-[#fff8f3]/80 px-3 py-1 text-sm font-medium text-[#6d5960]">
                  {filter}
                </span>
              ))}
            </div>
            <div className="mt-8 rounded-2xl border border-dashed border-[#d3aab2] bg-[#fff8f3]/70 p-6 text-center">
              <Film className="mx-auto size-8 text-[#b94e70]" aria-hidden="true" />
              <h2 className="mt-4 text-xl font-semibold">{text.gallery.emptyTitle}</h2>
              <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[#6d5960]">{text.gallery.emptyBody}</p>
            </div>
          </Card>

          <div className="grid gap-4">
            {text.gallery.hints.map((hint, index) => (
              <HintCard key={hint.title} icon={icons[index]} title={hint.title} text={hint.text} />
            ))}
          </div>
        </section>
      </AppShell>
    </ProtectedRoute>
  );
}

function HintCard({ icon, text, title }: { icon: ReactNode; text: string; title: string }) {
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
