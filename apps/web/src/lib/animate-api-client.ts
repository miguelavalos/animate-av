import { getAnimateApiBaseUrl } from "@/lib/animate-config";
import type {
  AnimateArtifactDownloadResponse,
  AnimateConfirmFinalRenderResponse,
  AnimateCreditBalance,
  AnimatePreparedUpload,
  AnimateRenderPlanResponse,
  AnimateUploadCompletion
} from "@/lib/animate-models";

export interface AnimateApiClientOptions {
  getToken: () => Promise<string | null>;
  baseUrl?: string;
}

export interface PrepareUploadInput {
  videoId: string;
  sourceLocalIdentifier: string;
  originalFilename: string;
  contentType: string;
  byteSize: number;
  sha256: string;
  width?: number;
  height?: number;
}

export interface RenderPlanInput {
  videoId: string;
  look: string;
  actionHint?: string | null;
  selectedSourceLocalIdentifiers: string[];
  sourceImageUploadId?: string | null;
  hasMessage: boolean;
  messageText?: string | null;
  removeWatermark?: boolean;
  startsWithSourcePhoto: boolean;
}

export interface ConfirmFinalRenderInput extends RenderPlanInput {
  planId: string;
  idempotencyKey: string;
}

export interface RenderPlanPayloadOptions {
  mockNoSpendFinalRender?: boolean;
}

interface ApiErrorBody {
  error?: {
    code?: string;
    message?: string;
  };
}

export class AnimateApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = "AnimateApiError";
    this.status = status;
    this.code = code;
  }
}

export class AnimateApiClient {
  private readonly baseUrl: string;
  private readonly getToken: () => Promise<string | null>;

  constructor(options: AnimateApiClientOptions) {
    this.baseUrl = (options.baseUrl ?? getAnimateApiBaseUrl()).replace(/\/+$/, "");
    this.getToken = options.getToken;
  }

  async getCreditBalance() {
    return this.request<AnimateCreditBalance>("/v1/apps/animateav/credits/balance", {
      method: "GET"
    });
  }

  async createRealtimeSession() {
    return this.request<{ realtimeSessionId: string }>("/v1/apps/animateav/workspace/realtime-sessions", {
      method: "POST",
      body: JSON.stringify({})
    });
  }

  async renameVideoJob(videoId: string, title: string) {
    const normalizedVideoId = requireNonEmpty(videoId, "animate_video_id_required", "Video id is required.");
    return this.request<{ videoId: string }>(`/v1/apps/animateav/workspace/videos/${encodeURIComponent(normalizedVideoId)}/title`, {
      method: "PATCH",
      body: JSON.stringify(buildRenameVideoPayload(normalizedVideoId, title))
    });
  }

  async deleteVideoJob(videoId: string) {
    const normalizedVideoId = requireNonEmpty(videoId, "animate_video_id_required", "Video id is required.");
    return this.request<{ videoId: string }>(`/v1/apps/animateav/workspace/videos/${encodeURIComponent(normalizedVideoId)}`, {
      method: "DELETE"
    });
  }

  async prepareUpload(input: PrepareUploadInput) {
    return this.request<AnimatePreparedUpload>("/v1/apps/animateav/media/prepare-upload", {
      method: "POST",
      body: JSON.stringify(buildPrepareUploadPayload(input))
    });
  }

  async uploadPrepared(file: File, preparedUpload: AnimatePreparedUpload) {
    const uploadUrl = requireHttpUrl(preparedUpload.uploadUrl, "animate_upload_url_required", "Upload URL is required.");
    const method = requireAllowedHttpMethod(preparedUpload.method, ["PUT", "POST"], "animate_upload_method_required", "Upload method is required.");
    const videoId = requireNonEmpty(preparedUpload.videoId, "animate_video_id_required", "Video id is required.");
    const response = await fetch(uploadUrl, {
      method,
      headers: {
        ...preparedUpload.headers,
        "x-appsav-animate-video-id": videoId,
        "x-appsav-videos-sort-order": "0",
        "x-appsav-videos-selected": "true"
      },
      body: file
    });

    if (!response.ok) {
      throw await this.errorFromResponse(response, "animate_upload_failed", "Media upload failed.");
    }

    if (preparedUpload.completionUrl) {
      return this.completeUpload(preparedUpload);
    }

    return response.json() as Promise<AnimateUploadCompletion>;
  }

  async completeUpload(preparedUpload: AnimatePreparedUpload) {
    if (!preparedUpload.completionUrl) {
      throw new AnimateApiError(409, "animate_upload_completion_missing", "Upload completion is not available.");
    }
    const completionUrl = requireHttpUrl(preparedUpload.completionUrl, "animate_upload_completion_url_required", "Upload completion URL is required.");

    const response = await fetch(completionUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sortOrder: 0, selected: true })
    });

    if (!response.ok) {
      throw await this.errorFromResponse(response, "animate_upload_complete_failed", "Upload completion failed.");
    }

    return response.json() as Promise<AnimateUploadCompletion>;
  }

  async prepareRenderPlan(input: RenderPlanInput) {
    return this.request<AnimateRenderPlanResponse>("/v1/apps/animateav/renders/plan", {
      method: "POST",
      body: JSON.stringify(buildRenderPlanPayload(input, { mockNoSpendFinalRender: shouldUseMockNoSpendFinalRender() }))
    });
  }

  async confirmFinalRender(input: ConfirmFinalRenderInput) {
    return this.request<AnimateConfirmFinalRenderResponse>("/v1/apps/animateav/renders/final/confirm", {
      method: "POST",
      body: JSON.stringify(buildConfirmFinalRenderPayload(input, { mockNoSpendFinalRender: shouldUseMockNoSpendFinalRender() }))
    });
  }

  async prepareArtifactDownload(artifactId: string) {
    const normalizedArtifactId = requireNonEmpty(artifactId, "animate_artifact_id_required", "Artifact id is required.");
    return this.request<AnimateArtifactDownloadResponse>(`/v1/apps/animateav/artifacts/${encodeURIComponent(normalizedArtifactId)}/download`, {
      method: "POST",
      body: JSON.stringify(buildArtifactDownloadPayload(normalizedArtifactId))
    });
  }

  async downloadBlob(download: AnimateArtifactDownloadResponse) {
    const downloadUrl = requireHttpUrl(download.downloadUrl, "animate_download_url_required", "Download URL is required.");
    const method = requireAllowedHttpMethod(download.method, ["GET"], "animate_download_method_required", "Download method is required.");
    const response = await fetch(downloadUrl, {
      method,
      headers: download.headers
    });
    if (!response.ok) {
      throw await this.errorFromResponse(response, "animate_artifact_download_failed", "Video download failed.");
    }
    return response.blob();
  }

  private async request<T>(path: string, init: RequestInit) {
    const token = await this.getToken();
    if (!token) {
      throw new AnimateApiError(401, "animate_auth_required", "Sign in again to continue.");
    }

    const response = await fetch(`${this.baseUrl}${path}`, {
      ...init,
      headers: {
        ...(init.body ? { "Content-Type": "application/json" } : {}),
        ...init.headers,
        Authorization: `Bearer ${token}`
      }
    });

    if (!response.ok) {
      throw await this.errorFromResponse(response, "animate_request_failed", "Animate AV request failed.");
    }

    return response.json() as Promise<T>;
  }

  private async errorFromResponse(response: Response, fallbackCode: string, fallbackMessage: string) {
    let body: ApiErrorBody | null = null;
    try {
      body = await response.json() as ApiErrorBody;
    } catch {
      body = null;
    }

    return new AnimateApiError(
      response.status,
      body?.error?.code ?? fallbackCode,
      body?.error?.message ?? fallbackMessage
    );
  }
}

export function buildRenderPlanPayload(input: RenderPlanInput, options: RenderPlanPayloadOptions = {}) {
  const videoId = requireNonEmpty(input.videoId, "animate_video_id_required", "Video id is required.");
  const look = requireNonEmpty(input.look, "animate_look_required", "Look is required.");
  const selectedSourceLocalIdentifiers = input.selectedSourceLocalIdentifiers.map((identifier) => identifier.trim()).filter(Boolean);
  if (selectedSourceLocalIdentifiers.length === 0) {
    throw new AnimateApiError(400, "animate_source_local_identifier_required", "Source image selection is required.");
  }
  const sourceImageUploadId = requireNonEmpty(input.sourceImageUploadId ?? "", "animate_source_image_upload_required", "Source image upload is required.");
  return {
    videoId,
    look,
    actionHint: input.actionHint?.trim() || null,
    selectedSourceLocalIdentifiers,
    sourceImageUploadId,
    hasMessage: input.hasMessage,
    messageText: input.hasMessage ? input.messageText?.trim() || null : null,
    removeWatermark: input.removeWatermark ?? false,
    startsWithSourcePhoto: input.startsWithSourcePhoto,
    ...mockNoSpendPayload(options)
  };
}

export function buildPrepareUploadPayload(input: PrepareUploadInput) {
  return {
    appId: "animateav",
    videoId: requireNonEmpty(input.videoId, "animate_video_id_required", "Video id is required."),
    mediaKind: "photo",
    sourceLocalIdentifier: requireNonEmpty(input.sourceLocalIdentifier, "animate_source_local_identifier_required", "Source image selection is required."),
    originalFilename: requireNonEmpty(input.originalFilename, "animate_original_filename_required", "Original filename is required."),
    contentType: requireNonEmpty(input.contentType, "animate_content_type_required", "Content type is required."),
    byteSize: requirePositiveFinite(input.byteSize, "animate_byte_size_required", "File size is required."),
    sha256: requireNonEmpty(input.sha256, "animate_sha256_required", "File checksum is required."),
    width: optionalPositiveFinite(input.width, "animate_width_invalid", "Image width is invalid."),
    height: optionalPositiveFinite(input.height, "animate_height_invalid", "Image height is invalid.")
  };
}

export function buildRenameVideoPayload(videoId: string, title: string) {
  requireNonEmpty(videoId, "animate_video_id_required", "Video id is required.");
  const normalizedTitle = requireNonEmpty(title, "animate_video_title_required", "Video title is required.");
  return { title: normalizedTitle };
}

export function buildArtifactDownloadPayload(artifactId: string) {
  return { artifactId: requireNonEmpty(artifactId, "animate_artifact_id_required", "Artifact id is required.") };
}

export function buildConfirmFinalRenderPayload(input: ConfirmFinalRenderInput, options: RenderPlanPayloadOptions = {}) {
  const planId = input.planId.trim();
  const idempotencyKey = input.idempotencyKey.trim();
  if (!planId) {
    throw new AnimateApiError(400, "animate_plan_id_required", "Render plan is required before final confirmation.");
  }
  if (!idempotencyKey) {
    throw new AnimateApiError(400, "animate_idempotency_key_required", "Idempotency key is required before final confirmation.");
  }

  return {
    ...buildRenderPlanPayload(input, options),
    planId,
    idempotencyKey
  };
}

function shouldUseMockNoSpendFinalRender() {
  return import.meta.env.VITE_ANIMATEAV_MOCK_NO_SPEND_FINAL_RENDER === "true";
}

function requireNonEmpty(value: string, code: string, message: string) {
  const trimmed = value.trim();
  if (!trimmed) {
    throw new AnimateApiError(400, code, message);
  }
  return trimmed;
}

export function requireHttpUrl(value: string | null | undefined, code: string, message: string) {
  const trimmed = requireNonEmpty(value ?? "", code, message);
  try {
    const url = new URL(trimmed);
    if (url.protocol === "https:" || url.protocol === "http:") {
      return url.toString();
    }
  } catch {
    // handled below
  }
  throw new AnimateApiError(400, code, message);
}

export function requireAllowedHttpMethod(value: string | null | undefined, allowedMethods: string[], code: string, message: string) {
  const method = requireNonEmpty(value ?? "", code, message).toUpperCase();
  if (!allowedMethods.includes(method)) {
    throw new AnimateApiError(400, code, message);
  }
  return method;
}

function requirePositiveFinite(value: number, code: string, message: string) {
  if (!Number.isFinite(value) || value <= 0) {
    throw new AnimateApiError(400, code, message);
  }
  return value;
}

function optionalPositiveFinite(value: number | undefined, code: string, message: string) {
  if (value === undefined) {
    return undefined;
  }
  return requirePositiveFinite(value, code, message);
}

function mockNoSpendPayload(options: RenderPlanPayloadOptions) {
  if (options.mockNoSpendFinalRender !== true) {
    return {};
  }
  return {
    mockNoSpend: true,
    mockExecutionPreset: "all_mock"
  };
}
