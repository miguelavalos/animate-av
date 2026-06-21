import type { AppsAvProductConfig } from "@avalsys/apps-av-web";

const animateCommercialWordmarkUrl = "https://cdn.avalsys.com/apps-av/animate-av/web-v2/animate-av-wordmark-transparent.png";

export const animateProductConfig: AppsAvProductConfig = {
  appId: "animateav",
  accentColor: "#B94E70",
  assistant: {
    href: "/avi",
    imageSrc: "/assets/avi-footer-icon.png",
    label: "Open Avi guidance",
    name: "Avi"
  },
  iconSrc: "/assets/animate-av-icon.png",
  logoSrc: animateCommercialWordmarkUrl,
  logoDarkSrc: animateCommercialWordmarkUrl,
  name: "Animate AV",
  links: {
    deleteAccount: externalLink(accountManagementUrl("/account/delete"), "Delete account"),
    privacy: externalLink(import.meta.env.VITE_ANIMATEAV_PRIVACY_URL, "Privacy"),
    suite: externalLink(import.meta.env.VITE_ACCOUNTAV_MANAGEMENT_URL, "Apps"),
    support: externalLink(supportUrl(), "Support"),
    terms: externalLink(import.meta.env.VITE_ANIMATEAV_TERMS_URL, "Terms"),
    website: externalLink("https://animate-av.avalsys.com", "Animate AV")
  }
};

export const animateBrandAssets = {
  aviFullBody: "/assets/avi-full-body.png",
  aviLoginPeek: "/assets/animate-av-splash.jpg",
  aviLoginSheetPeek: "/assets/avi-login-sheet-peek.png",
  aviOnboardingCta: "/assets/avi-onboarding-cta.png",
  guestHomeMotion: "/assets/animate-av-guest-home-1.webp",
  guestHomeLooks: "/assets/animate-av-guest-home-2.webp",
  guestHomeReview: "/assets/animate-av-guest-home-3.webp",
  hero: "/assets/animate-av-splash.jpg",
  logo: "/assets/animate-av-logo.png",
  mark: "/assets/animate-av-mark.png",
  onboarding: "/assets/animate-av-onboarding.jpg",
  wordmark: "/assets/animate-av-wordmark.png"
} as const;

export function getAnimateApiBaseUrl() {
  return requiredUrl(import.meta.env.VITE_ANIMATEAV_API_BASE_URL, "VITE_ANIMATEAV_API_BASE_URL");
}

export function getAccountApiBaseUrl() {
  return requiredUrl(import.meta.env.VITE_ACCOUNTAV_API_BASE_URL, "VITE_ACCOUNTAV_API_BASE_URL");
}

export function getAccountPublishableKey() {
  return import.meta.env.VITE_ACCOUNTAV_PUBLISHABLE_KEY as string | undefined;
}

export function getAccountCreditsUrl() {
  return accountManagementUrl("/credits") || accountManagementUrl("/");
}

export function getAnimateConvexUrl() {
  return trimTrailingSlash(import.meta.env.VITE_ANIMATEAV_CONVEX_URL);
}

function requiredUrl(value: string | undefined, key: string) {
  const normalized = trimTrailingSlash(value);
  if (!normalized) {
    throw new Error(`${key} is required.`);
  }
  return normalized;
}

function accountManagementUrl(path: string) {
  const baseUrl = trimTrailingSlash(import.meta.env.VITE_ACCOUNTAV_MANAGEMENT_URL);
  return baseUrl ? `${baseUrl}${path}` : undefined;
}

function supportUrl() {
  return trimTrailingSlash(import.meta.env.VITE_SUPPORTAV_BASE_URL) || commercialSiteUrl("/support");
}

function commercialSiteUrl(path: string) {
  const privacyUrl = trimTrailingSlash(import.meta.env.VITE_ANIMATEAV_PRIVACY_URL);
  const url = privacyUrl ? new URL(privacyUrl) : new URL("https://animate-av.avalsys.com");
  return `${url.origin}${path}`;
}

function externalLink(href: string | undefined, label: string) {
  const normalized = normalizeHref(href);
  return normalized ? { href: normalized, label, external: true } : undefined;
}

function normalizeHref(value: string | undefined) {
  if (!value) {
    return "";
  }

  return value.startsWith("mailto:") ? value.trim() : trimTrailingSlash(value);
}

function trimTrailingSlash(value: string | undefined) {
  return value?.trim().replace(/\/+$/, "") ?? "";
}
