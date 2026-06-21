#!/usr/bin/env node

import { runSharedWebSmokeQa } from "../../../../apps-av/web/scripts/shared-web-smoke-qa.mjs";

const result = await runSharedWebSmokeQa({
  baseUrl: process.env.ANIMATEAV_WEB_QA_BASE_URL ?? "http://localhost:5195",
  guestCopyPattern: /\b(guest-mode|invitado|invitada|convidat|convidada|gastmodus)\b/i,
  expectations: {
    ca: {
      protectedTitle: "Les teves creacions queden darrere del teu compte AV",
      publicCopy: "Anima una imatge en un video curt",
      signInCopy: "Inicia sessio",
      signInRouteCopy: "Inicia sessio per mantenir"
    },
    de: {
      protectedTitle: "Deine Kreationen bleiben hinter deinem AV-Konto",
      publicCopy: "Ein Bild als kurzes Video animieren",
      signInCopy: "Anmelden",
      signInRouteCopy: "Melde dich an"
    },
    en: {
      protectedTitle: "Your creations stay behind your AV account",
      publicCopy: "Animate one image",
      signInCopy: "Sign in",
      signInRouteCopy: "Sign in to keep"
    },
    es: {
      protectedTitle: "Tus creaciones permanecen detras de tu cuenta AV",
      publicCopy: "Anima una imagen en un video corto",
      signInCopy: "Iniciar sesion",
      signInRouteCopy: "Inicia sesion para mantener"
    },
    fr: {
      protectedTitle: "Vos creations restent derriere votre compte AV",
      publicCopy: "Animez une image",
      signInCopy: "Se connecter",
      signInRouteCopy: "Connectez-vous pour garder"
    }
  },
  name: "Animate AV",
  ownRoutePrefixes: ["/", "/create", "/in-progress", "/gallery", "/avi", "/sign-in"],
  productIdentity: "Animate AV",
  routes: ["/", "/sign-in", "/create", "/in-progress", "/gallery", "/avi"],
  signInRoutes: ["/sign-in"]
});

if (!result.passed) {
  process.exit(1);
}
