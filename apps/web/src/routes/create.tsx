import { AccountUserButton } from "@avalsys/account-av-web";
import { AppShell } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { Film, Images, SlidersHorizontal } from "lucide-react";
import type { ReactNode } from "react";
import { ProtectedRoute } from "@/components/protected-route";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { animateBrandAssets } from "@/lib/animate-config";
import { useAnimateNavLinks, useAnimateProductConfig, useAnimateShellLabels, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/create")({
  component: CreateRoute
});

function CreateRoute() {
  const text = useAnimateText();
  const navLinks = useAnimateNavLinks();
  const productConfig = useAnimateProductConfig();
  const shellLabels = useAnimateShellLabels();
  const icons = [<Images className="size-4" />, <SlidersHorizontal className="size-4" />, <Film className="size-4" />];

  return (
    <ProtectedRoute>
      <AppShell accountArea={<AccountUserButton />} footerLabels={text.footer} labels={shellLabels} navLinks={navLinks} product={productConfig}>
        <section className="grid gap-6 lg:grid-cols-[1fr_23rem]">
          <Card className="animate-canvas gap-0 overflow-hidden rounded-[1.5rem] border-[#e5c1c7] p-6 py-6 text-[#20242e] shadow-lg shadow-[#7b233f]/8 sm:p-8 sm:py-8">
            <div className="max-w-3xl">
              <h1 className="text-4xl font-semibold leading-tight">{text.create.title}</h1>
              <p className="mt-4 max-w-2xl text-base leading-7 text-[#4d5563]">{text.create.body}</p>
            </div>
            <div className="mt-8 grid gap-4 md:grid-cols-3">
              {text.create.flow.map((step, index) => (
                <StepCard key={step.title} icon={icons[index]} title={step.title} text={step.text} />
              ))}
            </div>
            <Button className="mt-8 w-fit rounded-full bg-[#7c2947] px-5 text-white hover:bg-[#963956]">
              <Images className="size-4" aria-hidden="true" />
              {text.create.cta}
            </Button>
          </Card>

          <Card className="gap-0 overflow-hidden rounded-[1.5rem] border-[#e5c1c7] bg-[#20242e] p-0 text-white shadow-lg shadow-[#7b233f]/14">
            <img className="h-72 w-full object-cover object-center lg:h-full" src={animateBrandAssets.hero} alt="" />
          </Card>
        </section>
      </AppShell>
    </ProtectedRoute>
  );
}

function StepCard({ icon, text, title }: { icon: ReactNode; text: string; title: string }) {
  return (
    <div className="rounded-2xl border border-[#e5c1c7] bg-[#fff8f3]/78 p-4">
      <div className="flex items-center gap-2 text-sm font-semibold">
        <span className="text-[#b94e70]">{icon}</span>
        {title}
      </div>
      <p className="mt-3 text-sm leading-6 text-[#6d5960]">{text}</p>
    </div>
  );
}
