import { useAccountSession } from "@avalsys/account-av-web";
import { useAppsAvLocale } from "@avalsys/apps-av-web";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, CreditCard, Film, ImagePlus, Loader2, MessageSquare, Play, Upload } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import { AnimateAppShell } from "@/components/animate-app-shell";
import { ProtectedRoute } from "@/components/protected-route";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { useAnimateApiClient } from "@/lib/animate-client-hooks";
import { getAccountCreditsUrl } from "@/lib/animate-config";
import { localizedAnimateErrorMessage } from "@/lib/animate-errors";
import { createPortraitFrameFile, createSourceLocalIdentifier, createVideoId, fileTypeError, normalizeSourceImageFile, readImageDimensions, saveLocalInProgressJob, sha256Hex, sourceImageAccept } from "@/lib/animate-browser-utils";
import { animateLookFamilies, animateLookPreviewAssets, isAnimateFinalRenderLook, type AnimateLook, type AnimateRenderPlanResponse } from "@/lib/animate-models";
import { animateCreateInputLimits, canSubmitConfirm, createFinalConfirmIdempotencyKey, createRenderPlanInputSignature, finalRenderQueuedMessage, isRenderPlanCurrent, renderPlanBlockerSummary, spendableCredits } from "@/lib/animate-render-state";
import { localizedAppPath, useAnimateLookCopy, useAnimateText } from "@/lib/animate-i18n";

export const Route = createFileRoute("/create")({
  component: CreateRoute
});

type CreateStage = "source" | "look" | "animation" | "message" | "review";
type SourceFrameMode = "full" | "portrait";
interface QueuedRenderJob {
  jobId: string;
  title: string;
  videoId: string;
}

function CreateRoute() {
  return (
    <ProtectedRoute>
      <AnimateAppShell>
        <CreateVideoSurface />
      </AnimateAppShell>
    </ProtectedRoute>
  );
}

function CreateVideoSurface() {
  const text = useAnimateText();
  const locale = useAppsAvLocale();
  const lookCopy = useAnimateLookCopy();
  const api = useAnimateApiClient();
  const session = useAccountSession();
  const [stage, setStage] = useState<CreateStage>("source");
  const [videoId, setVideoId] = useState(() => createVideoId());
  const [originalFile, setOriginalFile] = useState<File | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [frameMode, setFrameMode] = useState<SourceFrameMode>("full");
  const [sourceLocalIdentifier, setSourceLocalIdentifier] = useState("");
  const [sourceImageUploadId, setSourceImageUploadId] = useState("");
  const [look, setLook] = useState<AnimateLook>("cartoon");
  const [actionHint, setActionHint] = useState("");
  const [messageText, setMessageText] = useState("");
  const [startsWithSourcePhoto, setStartsWithSourcePhoto] = useState(true);
  const [renderPlan, setRenderPlan] = useState<AnimateRenderPlanResponse | null>(null);
  const [renderPlanSignature, setRenderPlanSignature] = useState<string | null>(null);
  const [queuedJob, setQueuedJob] = useState<QueuedRenderJob | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [confirming, setConfirming] = useState(false);
  const confirmInFlight = useRef<string | null>(null);
  const balanceQuery = useQuery({
    enabled: Boolean(session.isLoaded && session.isSignedIn),
    queryKey: ["animate-av", "credits", "balance", session.userId],
    queryFn: () => api.getCreditBalance(),
    staleTime: 30_000
  });

  const canReview = Boolean(file && sourceImageUploadId);
  const hasMessage = messageText.trim().length > 0;
  const creditCount = spendableCredits(balanceQuery.data, balanceQuery.isFetched);
  const accountCreditsUrl = getAccountCreditsUrl();
  const planInputSignature = useMemo(() => {
    return createRenderPlanInputSignature({
      videoId,
      sourceImageUploadId,
      sourceLocalIdentifier,
      frameMode,
      look,
      actionHint: actionHint.trim(),
      messageText: messageText.trim(),
      startsWithSourcePhoto
    });
  }, [actionHint, frameMode, look, messageText, sourceImageUploadId, sourceLocalIdentifier, startsWithSourcePhoto, videoId]);
  const renderPlanIsCurrent = isRenderPlanCurrent(renderPlanSignature, planInputSignature);

  useEffect(() => {
    return () => {
      if (previewUrl) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [previewUrl]);

  function updateSourceFile(nextFile: File, nextFrameMode: SourceFrameMode, nextPreviewUrl?: string) {
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
    }
    const objectUrl = nextPreviewUrl ?? URL.createObjectURL(nextFile);
    setFile(nextFile);
    setFrameMode(nextFrameMode);
    setSourceLocalIdentifier(`${createSourceLocalIdentifier(nextFile)}:${nextFrameMode}`);
    setPreviewUrl(objectUrl);
    setSourceImageUploadId("");
    setRenderPlan(null);
    setRenderPlanSignature(null);
    setQueuedJob(null);
    setStatus(null);
  }

  async function selectFile(nextFile: File | undefined) {
    if (!nextFile) {
      return;
    }
    const validationError = fileTypeError(nextFile, text.create.ui);
    if (validationError) {
      setError(validationError);
      return;
    }
    setError(null);
    setStatus(null);
    setRenderPlan(null);
    setRenderPlanSignature(null);
    setOriginalFile(nextFile);
    try {
      const normalizedFile = await normalizeSourceImageFile(nextFile, text.create.ui.imageReadFailed);
      updateSourceFile(normalizedFile, "full");
    } catch {
      updateSourceFile(nextFile, "full");
    }
  }

  async function applyFrameMode(nextFrameMode: SourceFrameMode) {
    if (!originalFile) {
      setError(text.create.ui.chooseSourceFirst);
      return;
    }
    setBusy(true);
    setError(null);
    try {
      if (nextFrameMode === "full") {
        updateSourceFile(originalFile, "full");
      } else {
        const framedFile = await createPortraitFrameFile(originalFile, text.create.ui.imageReadFailed);
        updateSourceFile(framedFile, "portrait");
        setStatus(text.create.ui.frameApplied);
      }
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, text.errors));
    } finally {
      setBusy(false);
    }
  }

  async function uploadSource() {
    if (!file) {
      setError(text.create.ui.chooseSourceFirst);
      return;
    }
    setBusy(true);
    setError(null);
    setStatus(text.create.ui.preparingUpload);
    try {
      const dimensions = await readImageDimensions(file, text.create.ui.imageReadFailed);
      const sha256 = await sha256Hex(file);
      const prepared = await api.prepareUpload({
        videoId,
        sourceLocalIdentifier,
        originalFilename: file.name || "animate-source-image",
        contentType: file.type || "application/octet-stream",
        byteSize: file.size,
        sha256,
        width: dimensions.width,
        height: dimensions.height
      });
      setStatus(text.create.ui.uploadingSource);
      const completion = await api.uploadPrepared(file, prepared);
      const uploadId = completion.sourceImageUploadId ?? completion.uploadId ?? prepared.uploadId;
      setSourceImageUploadId(uploadId);
      setStatus(text.create.ui.sourceReady);
      setStage("look");
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, text.errors));
      setStatus(null);
    } finally {
      setBusy(false);
    }
  }

  async function checkCost() {
    if (!canReview) {
      setError(text.create.ui.uploadBeforeCost);
      return;
    }
    if (!isAnimateFinalRenderLook(look)) {
      setError(`${lookCopy.titles[look]}: ${text.create.ui.comingSoon}`);
      return;
    }
    setBusy(true);
    setError(null);
    setStatus(text.create.ui.checkingCost);
    setQueuedJob(null);
    try {
      const plan = await api.prepareRenderPlan({
        videoId,
        look,
        actionHint,
        selectedSourceLocalIdentifiers: [sourceLocalIdentifier],
        sourceImageUploadId,
        hasMessage,
        messageText,
        removeWatermark: false,
        startsWithSourcePhoto
      });
      setRenderPlan(plan);
      setRenderPlanSignature(planInputSignature);
      setStatus(plan.canCreateVideo ? text.create.ui.planReady : text.create.ui.planBlockers);
      setStage("review");
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, text.errors));
      setStatus(null);
    } finally {
      setBusy(false);
    }
  }

  async function confirmFinalVideo() {
    if (!renderPlan?.canCreateVideo) {
      setError(text.create.ui.reviewCreatable);
      return;
    }
    if (!renderPlanIsCurrent) {
      setError(text.create.ui.reviewCurrentPlan);
      return;
    }
    const idempotencyKey = createFinalConfirmIdempotencyKey({ videoId, planId: renderPlan.planId, inputSignature: planInputSignature });
    if (!canSubmitConfirm(confirmInFlight.current, idempotencyKey)) {
      return;
    }
    confirmInFlight.current = idempotencyKey;
    setConfirming(true);
    setError(null);
    setStatus(text.create.ui.submittingFinal);
    try {
      const response = await api.confirmFinalRender({
        videoId,
        look,
        actionHint,
        selectedSourceLocalIdentifiers: [sourceLocalIdentifier],
        sourceImageUploadId,
        hasMessage,
        messageText,
        removeWatermark: renderPlan.watermark?.selectedRemoveWatermark ?? false,
        startsWithSourcePhoto,
        planId: renderPlan.planId,
        idempotencyKey
      });
      const now = Date.now();
      const title = file?.name ? `Animate ${file.name}` : text.gallery.defaultTitle;
      const jobId = response.workflow?.renderJobId ?? response.videoId;
      saveLocalInProgressJob({
        id: jobId,
        videoId: response.videoId,
        workflowRunId: response.workflow?.workflowRunId,
        renderJobId: response.workflow?.renderJobId,
        title,
        status: response.workflow?.status ?? "queued",
        phase: "queued",
        look,
        totalCreditCost: response.renderPlan?.plan.totalCreditCost ?? renderPlan.plan.totalCreditCost,
        createdAt: now,
        updatedAt: now
      });
      setQueuedJob({ jobId, title, videoId: response.videoId });
      setStatus(finalRenderQueuedMessage(text.create.ui));
      setRenderPlan(null);
      setRenderPlanSignature(null);
    } catch (nextError) {
      setError(localizedAnimateErrorMessage(nextError, text.errors));
      confirmInFlight.current = null;
    } finally {
      setConfirming(false);
    }
  }

  function reset() {
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
    }
    setStage("source");
    setVideoId(createVideoId());
    setOriginalFile(null);
    setFile(null);
    setPreviewUrl(null);
    setFrameMode("full");
    setSourceLocalIdentifier("");
    setSourceImageUploadId("");
    setLook("cartoon");
    setActionHint("");
    setMessageText("");
    setStartsWithSourcePhoto(true);
    setRenderPlan(null);
    setRenderPlanSignature(null);
    setQueuedJob(null);
    setStatus(null);
    setError(null);
    confirmInFlight.current = null;
  }

  return (
    <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_24rem]">
      <Card className="animate-canvas gap-0 overflow-hidden rounded-lg border-[#e5c1c7] p-5 text-[#20242e] shadow-lg shadow-[#7b233f]/8 sm:p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase text-[#b94e70]">{text.nav.create}</p>
            <h1 className="mt-2 text-3xl font-semibold leading-tight">{text.create.title}</h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-[#4d5563]">
              {text.create.body}
            </p>
          </div>
          <Button type="button" variant="outline" className="rounded-md border-[#d7b0b8] bg-white/60" onClick={reset} disabled={busy || confirming}>
            {text.create.ui.newSetup}
          </Button>
        </div>

        <div className="mt-6 grid gap-3 md:grid-cols-5">
          {([
            ["source", text.create.steps.source, ImagePlus],
            ["look", text.create.steps.look, CheckCircle2],
            ["animation", text.create.steps.animation, Play],
            ["message", text.create.steps.message, MessageSquare],
            ["review", text.create.steps.review, CreditCard]
          ] satisfies Array<[CreateStage, string, LucideIcon]>).map(([id, label, Icon]) => (
            <button
              key={id as string}
              type="button"
              className={`flex h-12 items-center justify-center gap-2 rounded-md border text-sm font-semibold ${stage === id ? "border-[#7c2947] bg-[#7c2947] text-white" : "border-[#e5c1c7] bg-white/62 text-[#5c4450]"}`}
              onClick={() => setStage(id as CreateStage)}
            >
              <Icon className="size-4" aria-hidden="true" />
              {label}
            </button>
          ))}
        </div>

        <div className="mt-6">
          {stage === "source" ? (
            <SourceStep file={file} frameMode={frameMode} previewUrl={previewUrl} busy={busy} uploaded={Boolean(sourceImageUploadId)} onFrameModeChange={applyFrameMode} onSelectFile={selectFile} onUpload={uploadSource} />
          ) : null}
          {stage === "look" ? <LookStep look={look} setLook={setLook} /> : null}
          {stage === "animation" ? (
            <AnimationStep actionHint={actionHint} setActionHint={setActionHint} startsWithSourcePhoto={startsWithSourcePhoto} setStartsWithSourcePhoto={setStartsWithSourcePhoto} />
          ) : null}
          {stage === "message" ? <MessageStep messageText={messageText} setMessageText={setMessageText} /> : null}
          {stage === "review" ? (
            <ReviewStep
              look={look}
              file={file}
              actionHint={actionHint}
              messageText={messageText}
              renderPlan={renderPlan}
              renderPlanIsCurrent={renderPlanIsCurrent}
              busy={busy}
              confirming={confirming}
              canReview={canReview}
              creditCount={creditCount}
              creditsHref={accountCreditsUrl}
              onCheckCost={checkCost}
              onConfirm={confirmFinalVideo}
            />
          ) : null}
        </div>

        {error ? <p className="mt-5 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">{error}</p> : null}
        {status ? <p className="mt-5 rounded-md border border-[#d7b0b8] bg-white/70 px-4 py-3 text-sm font-medium text-[#6d5960]">{status}</p> : null}
        {queuedJob ? (
          <div className="mt-5 rounded-lg border border-[#99d6bd] bg-[#f0fff8] p-4 text-sm text-[#28513e]">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="font-semibold text-[#173c2b]">{text.create.ui.queuedTitle}</p>
                <p className="mt-1 leading-6">{text.create.ui.queuedBody}</p>
                <p className="mt-1 text-xs font-medium opacity-75">{queuedJob.title}</p>
              </div>
              <div className="flex shrink-0 flex-wrap gap-2">
                <Button asChild type="button" className="rounded-md bg-[#28513e] text-white hover:bg-[#34694f]">
                  <a href={localizedAppPath("/in-progress", locale)}>{text.create.ui.openInProgress}</a>
                </Button>
                <Button asChild type="button" variant="outline" className="rounded-md border-[#99d6bd] bg-white/70">
                  <a href={localizedAppPath("/gallery", locale)}>{text.create.ui.openVideos}</a>
                </Button>
              </div>
            </div>
          </div>
        ) : null}
      </Card>

      <Card className="gap-0 rounded-lg border-[#e5c1c7] bg-[#20242e] p-5 text-white shadow-lg shadow-[#7b233f]/14">
        <p className="text-sm font-semibold text-[#f3b1bf]">{text.create.ui.setupSummary}</p>
        <div className="mt-5 grid gap-4 text-sm">
          <SummaryRow label={text.create.steps.source} value={file ? file.name : text.create.ui.noImageSelected} />
          <SummaryRow label={text.create.ui.frame} value={frameMode === "portrait" ? text.create.ui.framePortrait : text.create.ui.frameFull} />
          <SummaryRow label={text.create.ui.upload} value={sourceImageUploadId ? text.create.ui.ready : text.create.ui.pending} />
          <SummaryRow label={text.create.steps.look} value={lookCopy.titles[look]} />
          <SummaryRow label={text.create.steps.animation} value={actionHint.trim() || text.create.ui.noExtraGuidance} />
          <SummaryRow label={text.create.steps.message} value={messageText.trim() || text.create.ui.noSpokenMessage} />
          <SummaryRow label={text.create.ui.credits} value={creditCount === null ? text.create.ui.loading : `${creditCount} ${text.create.ui.available}`} />
          <SummaryRow label={text.create.ui.cost} value={renderPlan ? formatCreditCost(renderPlan.plan.totalCreditCost, text.create.ui) : text.create.ui.notChecked} />
        </div>
        <div className="mt-6 rounded-md border border-white/12 bg-white/8 p-4 text-sm leading-6 text-white/76">{text.create.flow[2]?.text}</div>
      </Card>
    </section>
  );
}

function SourceStep({ busy, file, frameMode, previewUrl, uploaded, onFrameModeChange, onSelectFile, onUpload }: {
  busy: boolean;
  file: File | null;
  frameMode: SourceFrameMode;
  previewUrl: string | null;
  uploaded: boolean;
  onFrameModeChange: (mode: SourceFrameMode) => void;
  onSelectFile: (file: File | undefined) => void;
  onUpload: () => void;
}) {
  const text = useAnimateText();
  const sourceCopy = text.create.flow[0] ?? { title: text.create.steps.source, text: text.create.body };
  return (
    <div className="grid gap-5 lg:grid-cols-[20rem_1fr]">
      <div className="flex aspect-[4/5] items-center justify-center overflow-hidden rounded-lg border border-dashed border-[#d3aab2] bg-white/58">
        {previewUrl ? <img src={previewUrl} alt="" className="h-full w-full object-contain" /> : <ImagePlus className="size-10 text-[#b94e70]" aria-hidden="true" />}
      </div>
      <div>
        <h2 className="text-xl font-semibold">{sourceCopy.title}</h2>
        <p className="mt-2 text-sm leading-6 text-[#6d5960]">{sourceCopy.text}</p>
        <Input className="mt-5 h-11 bg-white/70" type="file" accept={sourceImageAccept} onChange={(event) => void onSelectFile(event.target.files?.[0])} />
        <div className="mt-5 rounded-lg border border-[#e5c1c7] bg-white/55 p-4">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-sm font-semibold text-[#20242e]">{text.create.ui.frame}</p>
              <p className="mt-1 text-sm leading-6 text-[#6d5960]">{text.create.ui.frameHelp}</p>
            </div>
            <div className="flex shrink-0 rounded-md border border-[#d7b0b8] bg-white/72 p-1">
              {([
                ["full", text.create.ui.frameFull],
                ["portrait", text.create.ui.framePortrait]
              ] satisfies Array<[SourceFrameMode, string]>).map(([mode, label]) => (
                <button
                  key={mode}
                  type="button"
                  className={`h-9 rounded px-3 text-sm font-semibold ${frameMode === mode ? "bg-[#7c2947] text-white" : "text-[#5c4450] hover:bg-[#f7e7ea]"}`}
                  disabled={!file || busy}
                  onClick={() => void onFrameModeChange(mode)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        </div>
        <div className="mt-4 flex flex-wrap items-center gap-3">
          <Button type="button" className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]" disabled={!file || busy} onClick={() => void onUpload()}>
            {busy ? <Loader2 className="size-4 animate-spin" aria-hidden="true" /> : <Upload className="size-4" aria-hidden="true" />}
            {uploaded ? text.create.ui.uploadAgain : text.create.ui.prepareUpload}
          </Button>
          {file ? <span className="text-sm text-[#6d5960]">{file.name}</span> : null}
        </div>
      </div>
    </div>
  );
}

function LookStep({ look, setLook }: { look: AnimateLook; setLook: (look: AnimateLook) => void }) {
  const text = useAnimateText();
  const localizedLooks = useAnimateLookCopy();
  const lookCopy = text.create.flow[1] ?? { title: text.create.steps.look, text: text.create.body };
  return (
    <div>
      <h2 className="text-xl font-semibold">{lookCopy.title}</h2>
      <p className="mt-2 text-sm leading-6 text-[#6d5960]">{lookCopy.text}</p>
      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        {animateLookFamilies.map((family) => (
          <div key={family.id} className="rounded-lg border border-[#e5c1c7] bg-white/62 p-4">
            <div className="flex items-start justify-between gap-3">
              <div>
                <h3 className="font-semibold">{localizedLooks.families[family.id].title}</h3>
                <p className="mt-1 text-sm text-[#6d5960]">{localizedLooks.families[family.id].subtitle}</p>
              </div>
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2">
              {family.looks.map((entry) => (
                <LookOption key={entry} entry={entry} selected={look === entry} title={localizedLooks.titles[entry]} unavailableLabel={text.create.ui.comingSoon} onSelect={setLook} />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function LookOption({ entry, onSelect, selected, title, unavailableLabel }: {
  entry: AnimateLook;
  onSelect: (look: AnimateLook) => void;
  selected: boolean;
  title: string;
  unavailableLabel: string;
}) {
  const supported = isAnimateFinalRenderLook(entry);
  return (
    <button
      type="button"
      className={`grid min-h-24 grid-cols-[4.25rem_1fr] items-center gap-3 rounded-md border p-2 text-left text-sm font-semibold ${selected ? "border-[#7c2947] bg-[#7c2947] text-white" : "border-[#e5c1c7] bg-[#fff8f3]/76 text-[#5c4450]"} ${supported ? "" : "cursor-not-allowed opacity-55"}`}
      disabled={!supported}
      onClick={() => onSelect(entry)}
    >
      <img className="aspect-square w-full rounded-md object-cover" src={animateLookPreviewAssets[entry].path} alt="" loading="eager" />
      <span className="grid gap-1 leading-5">
        <span>{title}</span>
        {!supported ? <span className="text-xs font-medium opacity-80">{unavailableLabel}</span> : null}
      </span>
    </button>
  );
}

function AnimationStep({ actionHint, setActionHint, startsWithSourcePhoto, setStartsWithSourcePhoto }: {
  actionHint: string;
  setActionHint: (value: string) => void;
  startsWithSourcePhoto: boolean;
  setStartsWithSourcePhoto: (value: boolean) => void;
}) {
  const text = useAnimateText();
  return (
    <div className="max-w-3xl">
      <h2 className="text-xl font-semibold">{text.create.steps.animation}</h2>
      <p className="mt-2 text-sm leading-6 text-[#6d5960]">{text.avi.body}</p>
      <textarea
        className="mt-5 min-h-28 w-full rounded-md border border-[#d7b0b8] bg-white/70 p-3 text-sm outline-none focus:border-[#7c2947] focus:ring-2 focus:ring-[#7c2947]/20"
        maxLength={animateCreateInputLimits.actionHintMaxLength}
        value={actionHint}
        onChange={(event) => setActionHint(limitInputValue(event.target.value, animateCreateInputLimits.actionHintMaxLength))}
        placeholder={text.create.ui.animationPlaceholder}
      />
      <div className="mt-3 flex items-center justify-between gap-4 text-sm text-[#6d5960]">
        <label className="flex items-center gap-2 font-medium">
          <input type="checkbox" checked={startsWithSourcePhoto} onChange={(event) => setStartsWithSourcePhoto(event.target.checked)} />
          {text.create.ui.startFromSourcePhoto}
        </label>
        <span>{actionHint.length}/{animateCreateInputLimits.actionHintMaxLength}</span>
      </div>
    </div>
  );
}

function MessageStep({ messageText, setMessageText }: { messageText: string; setMessageText: (value: string) => void }) {
  const text = useAnimateText();
  return (
    <div className="max-w-3xl">
      <h2 className="text-xl font-semibold">{text.create.steps.message}</h2>
      <p className="mt-2 text-sm leading-6 text-[#6d5960]">{text.login.cardBody}</p>
      <textarea
        className="mt-5 min-h-32 w-full rounded-md border border-[#d7b0b8] bg-white/70 p-3 text-sm outline-none focus:border-[#7c2947] focus:ring-2 focus:ring-[#7c2947]/20"
        maxLength={animateCreateInputLimits.messageMaxLength}
        value={messageText}
        onChange={(event) => setMessageText(limitInputValue(event.target.value, animateCreateInputLimits.messageMaxLength))}
        placeholder={text.create.ui.messagePlaceholder}
      />
      <div className="mt-3 flex items-center justify-between gap-4 text-sm text-[#6d5960]">
        <Button type="button" variant="outline" className="rounded-md border-[#d7b0b8] bg-white/70" onClick={() => setMessageText("")}>
          {text.create.ui.clear}
        </Button>
        <span>{messageText.length}/{animateCreateInputLimits.messageMaxLength}</span>
      </div>
    </div>
  );
}

function ReviewStep({ actionHint, busy, canReview, confirming, creditCount, creditsHref, file, look, messageText, renderPlan, renderPlanIsCurrent, onCheckCost, onConfirm }: {
  actionHint: string;
  busy: boolean;
  canReview: boolean;
  confirming: boolean;
  creditCount: number | null;
  creditsHref?: string;
  file: File | null;
  look: AnimateLook;
  messageText: string;
  renderPlan: AnimateRenderPlanResponse | null;
  renderPlanIsCurrent: boolean;
  onCheckCost: () => void;
  onConfirm: () => void;
}) {
  const text = useAnimateText();
  const lookCopy = useAnimateLookCopy();
  const reviewCopy = text.create.flow[2] ?? { title: text.create.steps.review, text: text.create.body };
  const planCost = renderPlan?.plan.totalCreditCost ?? null;
  const insufficientCredits = creditCount !== null && planCost !== null && creditCount < planCost;
  const blockerText = renderPlanBlockerSummary(renderPlan?.createVideoBlockers, text.create.ui);

  return (
    <div className="grid gap-5 lg:grid-cols-[1fr_22rem]">
      <div className="rounded-lg border border-[#e5c1c7] bg-white/62 p-5">
        <h2 className="text-xl font-semibold">{reviewCopy.title}</h2>
        <div className="mt-4 grid gap-3 text-sm">
          <SummaryRow label={text.create.steps.source} value={file?.name ?? text.create.ui.missing} />
          <SummaryRow label={text.create.steps.look} value={lookCopy.titles[look]} />
          <SummaryRow label={text.create.steps.animation} value={actionHint.trim() || text.create.ui.noExtraGuidance} />
          <SummaryRow label={text.create.steps.message} value={messageText.trim() || text.create.ui.noSpokenMessage} />
        </div>
        <div className="mt-5 flex flex-wrap gap-3">
          <Button type="button" className="rounded-md bg-[#7c2947] text-white hover:bg-[#963956]" disabled={!canReview || busy || confirming} onClick={() => void onCheckCost()}>
            {busy ? <Loader2 className="size-4 animate-spin" aria-hidden="true" /> : <CreditCard className="size-4" aria-hidden="true" />}
            {text.create.ui.checkCost}
          </Button>
          <Button type="button" variant="outline" className="rounded-md border-[#d7b0b8] bg-white/70" disabled={!renderPlan?.canCreateVideo || !renderPlanIsCurrent || busy || confirming} onClick={() => void onConfirm()}>
            {confirming ? <Loader2 className="size-4 animate-spin" aria-hidden="true" /> : <Film className="size-4" aria-hidden="true" />}
            {text.create.ui.createFinalVideo}
          </Button>
          {insufficientCredits && creditsHref ? (
            <Button asChild type="button" variant="outline" className="rounded-md border-[#d7b0b8] bg-white/70">
              <a href={creditsHref}>{text.create.ui.openCredits}</a>
            </Button>
          ) : null}
        </div>
      </div>
      <div className="rounded-lg border border-[#e5c1c7] bg-[#fff8f3]/80 p-5">
        <h3 className="font-semibold">{text.create.ui.renderPlan}</h3>
        {renderPlan ? (
          <div className="mt-4 grid gap-3 text-sm text-[#5c4450]">
            <SummaryRow label={text.create.ui.cost} value={formatCreditCost(renderPlan.plan.totalCreditCost, text.create.ui)} />
            <SummaryRow label={text.create.ui.credits} value={formatCreditAvailability(creditCount, renderPlan.plan.totalCreditCost, text.create.ui)} />
            <SummaryRow label={text.create.ui.canCreate} value={renderPlan.canCreateVideo ? text.create.ui.yes : text.create.ui.no} />
            <SummaryRow label={text.create.ui.currentPlan} value={renderPlanIsCurrent ? text.create.ui.yes : text.create.ui.no} />
            <SummaryRow label={text.create.ui.blockers} value={blockerText} />
            {renderPlan.watermark ? (
              <>
                <SummaryRow label={text.create.ui.watermark} value={renderPlan.watermark.selectedRemoveWatermark ? text.create.ui.removalSelected : text.create.ui.standardWatermark} />
                <SummaryRow label={text.create.ui.removalCost} value={formatCreditCost(renderPlan.watermark.nonProRemovalCreditCost ?? renderPlan.watermark.watermarkCreditCost ?? 0, text.create.ui)} />
              </>
            ) : null}
          </div>
        ) : (
          <div className="mt-3 grid gap-3 text-sm leading-6 text-[#6d5960]">
            <p>{text.create.ui.noPlanYet} {text.create.ui.planAuthority}</p>
            <p>{formatCreditAvailability(creditCount, null, text.create.ui)}</p>
          </div>
        )}
      </div>
    </div>
  );
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-current/10 pb-2 last:border-0 last:pb-0">
      <span className="font-semibold opacity-72">{label}</span>
      <span className="max-w-[14rem] text-right opacity-90">{value}</span>
    </div>
  );
}

interface CreateCreditCopy {
  available: string;
  costUnit: string;
  costUnitPlural: string;
  loading: string;
}

function formatCreditCost(cost: number, copy: CreateCreditCopy) {
  return `${cost} ${cost === 1 ? copy.costUnit : copy.costUnitPlural}`;
}

function formatCreditAvailability(spendable: number | null, cost: number | null, copy: CreateCreditCopy) {
  if (cost === null) {
    return spendable === null ? copy.loading : `${spendable} ${copy.available}`;
  }
  if (spendable === null) {
    return `${copy.loading}. ${formatCreditCost(cost, copy)}`;
  }
  return `${spendable} ${copy.available}; ${formatCreditCost(cost, copy)}`;
}

function limitInputValue(value: string, maxLength: number) {
  return value.length > maxLength ? value.slice(0, maxLength) : value;
}
