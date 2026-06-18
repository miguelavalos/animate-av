import { useMemo } from "react";
import { useAppsAvLocale, type AppsAvLocale, type AppsAvProductConfig, type AppsAvProductLink } from "@avalsys/apps-av-web";
import { caES } from "@clerk/localizations/ca-ES";
import { deDE } from "@clerk/localizations/de-DE";
import { enUS } from "@clerk/localizations/en-US";
import { esES } from "@clerk/localizations/es-ES";
import { frFR } from "@clerk/localizations/fr-FR";
import { animateProductConfig } from "@/lib/animate-config";

const en = {
  account: {
    signInTitle: "Sign in to Animate AV",
    signInSubtitle: "Welcome back. Sign in to keep your animated video projects connected."
  },
  avi: {
    body: "Avi helps keep the creation path clear: one source image, a focused look, optional guidance, review, and final render when the signed-in workflow is available.",
    cards: [
      { title: "Keep one image central", text: "Start from the photo or generated image that should remain the visual reference." },
      { title: "Choose the look", text: "Use the style family and look before moving to guidance or cost review." },
      { title: "Review before render", text: "Credit and render steps stay behind the account boundary." }
    ],
    createCta: "Create video",
    galleryCta: "Open videos",
    title: "A guided path from image to animated video."
  },
  config: {
    body: "Run the web app through the Varlock wrapper so Account AV configuration is available. The public home is informational; product routes require login.",
    eyebrow: "Configuration required",
    title: "Animate AV Web needs Clerk configuration."
  },
  create: {
    body: "Prepare a short animated video from one image. The web port protects the product route first; upload, credit, and render actions stay behind signed-in backend wiring.",
    cta: "Protected creation flow",
    flow: [
      { title: "Choose one image", text: "Use a single source image so the animated result keeps a clear reference." },
      { title: "Pick style and guide", text: "Select the look and add optional short guidance before review." },
      { title: "Review cost", text: "Render confirmation remains account-owned and is not exposed in guest mode." }
    ],
    title: "Create an animated video from one image."
  },
  footer: {
    deleteAccount: "Delete account",
    language: "Language",
    privacy: "Privacy",
    support: "Support",
    terms: "Terms"
  },
  gallery: {
    body: "Signed-in creations will appear here for review, download, and return visits once the web workflow is connected.",
    emptyBody: "Create an animated video from a signed-in session and finished videos will be gathered here.",
    emptyTitle: "Your videos are ready for the first creation.",
    filters: ["All", "Rendering", "Ready", "Downloaded"],
    hints: [
      { title: "Review", text: "Check the generated result before saving or sharing." },
      { title: "Download", text: "Final videos are saved by the user when they are ready." },
      { title: "History", text: "Completed creations stay tied to the account for a calmer return flow." }
    ],
    kicker: "Videos",
    title: "Your animated videos, gathered in one place."
  },
  home: {
    aviBody: [
      "Start from one image and keep the visual reference clear.",
      "Pick a look, add optional short guidance, and review before render.",
      "Return to completed animated videos from your account."
    ],
    aviTitle: "Avi keeps the scene focused",
    body: "Animate AV turns one image into a short animated video through a signed-in creation flow.",
    cta: "Create video",
    items: [
      { label: "One image", value: "Keep the source scene central" },
      { label: "Look and guide", value: "Shape motion with restraint" },
      { label: "Videos", value: "Review finished creations" }
    ],
    title: "Animate one image into a short video."
  },
  login: {
    aviGuidance: "Avi guidance",
    cardBody: "Move from image, to look, to review without exposing render actions outside the account.",
    cardTitle: "A signed-in creation path",
    cta: "Sign in",
    heroBody: "Sign in to create animated videos, keep projects connected, and review each render from your AV account.",
    heroTitle: "One image, guided into motion.",
    intro: "Animate AV keeps video creation focused: one image, a clear look, optional guidance, and account-owned render review.",
    mapBody: "The web app carries Animate AV's visual language into a protected creation surface without guest-mode rendering.",
    mapTitle: "A focused path from source image to video.",
    notebook: "Videos",
    search: "Source image"
  },
  nav: {
    avi: "Avi",
    aviLabel: "Open Avi guidance",
    create: "Create",
    createLabel: "Create animated video",
    gallery: "Videos",
    galleryLabel: "Open Animate AV videos",
    home: "Home",
    homeLabel: "Animate AV home",
    mobileNavigation: "Mobile navigation",
    openNavigation: "Open navigation",
    primaryNavigation: "Primary navigation"
  },
  protected: {
    body: "Sign in to open creation, videos, and Avi routes. Animate AV web does not expose product functionality in guest mode.",
    cta: "Sign in",
    title: "Your creations stay behind your AV account."
  },
  signIn: {
    aviPanelBody: "Avi keeps the source image and motion guidance aligned.",
    body: "Sign in to keep source images, creation options, render status, and final videos connected with your AV account.",
    continue: "Continue",
    signedIn: "You are signed in.",
    title: "Animate AV is ready for your next video."
  }
};

type AnimateText = typeof en;

const translations: Record<AppsAvLocale, AnimateText> = {
  en,
  es: {
    account: { signInTitle: "Inicia sesión en Animate AV", signInSubtitle: "Vuelve para mantener conectados tus proyectos de video animado." },
    avi: {
      body: "Avi mantiene claro el camino de creación: una imagen, un estilo enfocado, guía opcional, revisión y render final cuando el flujo con sesión esté disponible.",
      cards: [
        { title: "Mantén una imagen central", text: "Empieza con la foto o imagen generada que debe seguir siendo la referencia visual." },
        { title: "Elige el estilo", text: "Usa la familia visual y el look antes de pasar a guía o revisión de coste." },
        { title: "Revisa antes del render", text: "Los pasos de créditos y render permanecen detrás de la cuenta." }
      ],
      createCta: "Crear video",
      galleryCta: "Abrir videos",
      title: "Un camino guiado desde imagen a video animado."
    },
    config: {
      body: "Ejecuta la web con el wrapper de Varlock para que Account AV esté disponible. La home pública es informativa; las rutas de producto requieren login.",
      eyebrow: "Configuración requerida",
      title: "Animate AV Web necesita configuración de Clerk."
    },
    create: {
      body: "Prepara un video animado corto desde una imagen. El port web protege primero la ruta de producto; subida, créditos y render quedan detrás del backend con sesión.",
      cta: "Flujo protegido",
      flow: [
        { title: "Elige una imagen", text: "Usa una sola imagen fuente para que el resultado conserve una referencia clara." },
        { title: "Elige look y guía", text: "Selecciona el estilo y añade una guía breve opcional antes de revisar." },
        { title: "Revisa el coste", text: "La confirmación de render sigue siendo de la cuenta y no aparece en modo invitado." }
      ],
      title: "Crea un video animado desde una imagen."
    },
    footer: { deleteAccount: "Eliminar cuenta", language: "Idioma", privacy: "Privacidad", support: "Soporte", terms: "Términos" },
    gallery: {
      body: "Las creaciones con sesión aparecerán aquí para revisar, descargar y retomar cuando el flujo web esté conectado.",
      emptyBody: "Crea un video animado con sesión y los videos terminados se reunirán aquí.",
      emptyTitle: "Tus videos están listos para la primera creación.",
      filters: ["Todos", "Renderizando", "Listos", "Descargados"],
      hints: [
        { title: "Revisar", text: "Comprueba el resultado generado antes de guardar o compartir." },
        { title: "Descargar", text: "Los videos finales se guardan cuando están listos." },
        { title: "Historial", text: "Las creaciones completadas siguen unidas a la cuenta para volver con calma." }
      ],
      kicker: "Videos",
      title: "Tus videos animados, reunidos en un lugar."
    },
    home: {
      aviBody: ["Empieza con una imagen y mantén clara la referencia visual.", "Elige un look, añade guía breve opcional y revisa antes del render.", "Vuelve a tus videos animados desde tu cuenta."],
      aviTitle: "Avi mantiene enfocada la escena",
      body: "Animate AV convierte una imagen en un video animado corto mediante un flujo con sesión.",
      cta: "Crear video",
      items: [
        { label: "Una imagen", value: "Mantén central la escena fuente" },
        { label: "Look y guía", value: "Da forma al movimiento con control" },
        { label: "Videos", value: "Revisa creaciones terminadas" }
      ],
      title: "Anima una imagen en un video corto."
    },
    login: {
      aviGuidance: "Guía de Avi",
      cardBody: "Avanza de imagen, a look, a revisión sin exponer acciones de render fuera de la cuenta.",
      cardTitle: "Un camino con sesión",
      cta: "Iniciar sesión",
      heroBody: "Inicia sesión para crear videos animados, mantener proyectos conectados y revisar cada render desde tu cuenta AV.",
      heroTitle: "Una imagen, guiada hacia el movimiento.",
      intro: "Animate AV mantiene enfocada la creación: una imagen, un look claro, guía opcional y revisión de render desde la cuenta.",
      mapBody: "La web lleva el lenguaje visual de Animate AV a una superficie protegida sin render en modo invitado.",
      mapTitle: "Un camino enfocado desde imagen fuente a video.",
      notebook: "Videos",
      search: "Imagen fuente"
    },
    nav: {
      avi: "Avi",
      aviLabel: "Abrir guía de Avi",
      create: "Crear",
      createLabel: "Crear video animado",
      gallery: "Videos",
      galleryLabel: "Abrir videos de Animate AV",
      home: "Inicio",
      homeLabel: "Inicio de Animate AV",
      mobileNavigation: "Navegación móvil",
      openNavigation: "Abrir navegación",
      primaryNavigation: "Navegación principal"
    },
    protected: {
      body: "Inicia sesión para abrir creación, videos y Avi. Animate AV web no expone funcionalidad de producto en modo invitado.",
      cta: "Iniciar sesión",
      title: "Tus creaciones permanecen detrás de tu cuenta AV."
    },
    signIn: {
      aviPanelBody: "Avi mantiene alineadas la imagen fuente y la guía de movimiento.",
      body: "Inicia sesión para mantener imagen fuente, opciones de creación, estado de render y videos finales conectados con tu cuenta AV.",
      continue: "Continuar",
      signedIn: "Has iniciado sesión.",
      title: "Animate AV está listo para tu próximo video."
    }
  },
  fr: {
    ...en,
    account: { signInTitle: "Connectez-vous à Animate AV", signInSubtitle: "Gardez vos projets de vidéo animée connectés." },
    footer: { deleteAccount: "Supprimer le compte", language: "Langue", privacy: "Confidentialité", support: "Assistance", terms: "Conditions" },
    home: {
      ...en.home,
      aviBody: [
        "Partez d’une image et gardez la référence visuelle claire.",
        "Choisissez un style, ajoutez une courte indication facultative et relisez avant le rendu.",
        "Retrouvez les vidéos animées terminées depuis votre compte."
      ],
      items: [
        { label: "Une image", value: "Gardez la scène source au centre" },
        { label: "Style et guide", value: "Façonnez le mouvement avec retenue" },
        { label: "Vidéos", value: "Relisez les créations terminées" }
      ],
      body: "Animate AV transforme une image en courte vidéo animée dans un flux connecté.",
      cta: "Créer une vidéo",
      title: "Animez une image en courte vidéo."
    },
    login: {
      ...en.login,
      aviGuidance: "Guide Avi",
      cardBody: "Passez de l’image au style puis à la révision sans exposer le rendu hors du compte.",
      cardTitle: "Un parcours connecté",
      cta: "Se connecter",
      heroBody: "Connectez-vous pour créer des vidéos animées, garder vos projets connectés et revoir chaque rendu depuis votre compte AV.",
      heroTitle: "Une image, guidée vers le mouvement.",
      intro: "Animate AV garde la création vidéo ciblée : une image, un style clair, une indication facultative et une révision du rendu côté compte.",
      mapBody: "L’app web porte le langage visuel d’Animate AV vers une surface protégée sans rendu en mode invité.",
      mapTitle: "Un chemin ciblé de l’image source vers la vidéo.",
      notebook: "Vidéos",
      search: "Image source"
    },
    nav: {
      ...en.nav,
      create: "Créer",
      gallery: "Vidéos",
      home: "Accueil"
    },
    protected: {
      body: "Connectez-vous pour ouvrir création, vidéos et Avi. Animate AV web n’expose aucune fonctionnalité produit en mode invité.",
      cta: "Se connecter",
      title: "Vos créations restent derrière votre compte AV."
    },
    signIn: {
      ...en.signIn,
      continue: "Continuer",
      signedIn: "Vous êtes connecté.",
      title: "Animate AV est prêt pour votre prochaine vidéo."
    }
  },
  de: {
    ...en,
    account: { signInTitle: "Bei Animate AV anmelden", signInSubtitle: "Halte deine animierten Videoprojekte verbunden." },
    footer: { deleteAccount: "Konto löschen", language: "Sprache", privacy: "Datenschutz", support: "Support", terms: "Bedingungen" },
    home: {
      ...en.home,
      aviBody: [
        "Beginne mit einem Bild und halte die visuelle Referenz klar.",
        "Wähle einen Look, ergänze optional kurze Hinweise und prüfe vor dem Rendern.",
        "Kehre über dein Konto zu fertigen animierten Videos zurück."
      ],
      items: [
        { label: "Ein Bild", value: "Die Ausgangsszene bleibt zentral" },
        { label: "Look und Hinweis", value: "Bewegung kontrolliert formen" },
        { label: "Videos", value: "Fertige Kreationen prüfen" }
      ],
      body: "Animate AV verwandelt ein Bild in einem angemeldeten Ablauf in ein kurzes animiertes Video.",
      cta: "Video erstellen",
      title: "Ein Bild als kurzes Video animieren."
    },
    login: {
      ...en.login,
      aviGuidance: "Avi-Hinweise",
      cardBody: "Vom Bild zum Look und zur Prüfung, ohne Render-Aktionen außerhalb des Kontos zu zeigen.",
      cardTitle: "Ein angemeldeter Erstellungsweg",
      cta: "Anmelden",
      heroBody: "Melde dich an, um animierte Videos zu erstellen, Projekte verbunden zu halten und jeden Render über dein AV-Konto zu prüfen.",
      heroTitle: "Ein Bild, geführt in Bewegung.",
      intro: "Animate AV hält Videoerstellung fokussiert: ein Bild, ein klarer Look, optionale Hinweise und Render-Prüfung im Konto.",
      mapBody: "Die Web-App bringt die visuelle Sprache von Animate AV in eine geschützte Oberfläche ohne Rendern im Gastmodus.",
      mapTitle: "Ein fokussierter Weg vom Quellbild zum Video.",
      notebook: "Videos",
      search: "Quellbild"
    },
    nav: {
      ...en.nav,
      create: "Erstellen",
      gallery: "Videos",
      home: "Start"
    },
    protected: {
      body: "Melde dich an, um Erstellung, Videos und Avi zu öffnen. Animate AV Web zeigt keine Produktfunktionen im Gastmodus.",
      cta: "Anmelden",
      title: "Deine Kreationen bleiben hinter deinem AV-Konto."
    },
    signIn: {
      ...en.signIn,
      continue: "Weiter",
      signedIn: "Du bist angemeldet.",
      title: "Animate AV ist bereit für dein nächstes Video."
    }
  },
  ca: {
    ...en,
    account: { signInTitle: "Inicia sessió a Animate AV", signInSubtitle: "Mantén connectats els teus projectes de vídeo animat." },
    footer: { deleteAccount: "Elimina el compte", language: "Idioma", privacy: "Privadesa", support: "Suport", terms: "Condicions" },
    home: {
      ...en.home,
      aviBody: [
        "Comença amb una imatge i mantén clara la referència visual.",
        "Tria un look, afegeix una guia breu opcional i revisa abans del render.",
        "Torna als vídeos animats acabats des del teu compte."
      ],
      items: [
        { label: "Una imatge", value: "Mantén central l’escena font" },
        { label: "Look i guia", value: "Dona forma al moviment amb control" },
        { label: "Vídeos", value: "Revisa creacions acabades" }
      ],
      body: "Animate AV converteix una imatge en un vídeo animat curt dins d’un flux amb sessió.",
      cta: "Crea vídeo",
      title: "Anima una imatge en un vídeo curt."
    },
    login: {
      ...en.login,
      aviGuidance: "Guia de l’Avi",
      cardBody: "Avança d’imatge, a look, a revisió sense exposar accions de render fora del compte.",
      cardTitle: "Un camí amb sessió",
      cta: "Inicia sessió",
      heroBody: "Inicia sessió per crear vídeos animats, mantenir projectes connectats i revisar cada render des del teu compte AV.",
      heroTitle: "Una imatge, guiada cap al moviment.",
      intro: "Animate AV manté enfocada la creació: una imatge, un look clar, guia opcional i revisió del render des del compte.",
      mapBody: "La web porta el llenguatge visual d’Animate AV a una superfície protegida sense render en mode convidat.",
      mapTitle: "Un camí enfocat des de la imatge font fins al vídeo.",
      notebook: "Vídeos",
      search: "Imatge font"
    },
    nav: {
      ...en.nav,
      create: "Crea",
      gallery: "Vídeos",
      home: "Inici"
    },
    protected: {
      body: "Inicia sessió per obrir creació, vídeos i Avi. Animate AV web no exposa funcionalitat de producte en mode convidat.",
      cta: "Inicia sessió",
      title: "Les teves creacions queden darrere del teu compte AV."
    },
    signIn: {
      ...en.signIn,
      continue: "Continua",
      signedIn: "Has iniciat sessió.",
      title: "Animate AV està a punt per al teu proper vídeo."
    }
  }
};

export function useAnimateText() {
  return translations[useAppsAvLocale()];
}

export function useAnimateAccountLocalization() {
  const locale = useAppsAvLocale();
  const text = translations[locale];
  const base = { ca: caES, de: deDE, en: enUS, es: esES, fr: frFR }[locale];

  return {
    ...base,
    signIn: {
      ...base.signIn,
      start: {
        ...base.signIn?.start,
        subtitle: text.account.signInSubtitle,
        title: text.account.signInTitle
      }
    }
  };
}

export function useAnimateShellLabels() {
  const text = useAnimateText();
  return {
    assistant: text.nav.aviLabel,
    home: text.nav.homeLabel,
    mobileNavigation: text.nav.mobileNavigation,
    openNavigation: text.nav.openNavigation,
    primaryNavigation: text.nav.primaryNavigation
  };
}

export function useAnimateNavLinks(): AppsAvProductLink[] {
  const locale = useAppsAvLocale();
  const text = useAnimateText();
  return [
    { href: localizedAppPath("/", locale), label: text.nav.home },
    { href: localizedAppPath("/create", locale), label: text.nav.create },
    { href: localizedAppPath("/gallery", locale), label: text.nav.gallery },
    { href: localizedAppPath("/avi", locale), label: text.nav.avi }
  ];
}

export function useAnimateProductConfig(): AppsAvProductConfig {
  const locale = useAppsAvLocale();
  const text = useAnimateText();

  return useMemo(() => ({
    ...animateProductConfig,
    assistant: animateProductConfig.assistant
      ? {
        ...animateProductConfig.assistant,
        href: localizedAppPath(animateProductConfig.assistant.href, locale),
        label: text.nav.aviLabel
      }
      : undefined
  }), [locale, text.nav.aviLabel]);
}

export function localizedAppPath(path: string, locale: AppsAvLocale): string {
  if (locale === "en") {
    return path;
  }

  const separator = path.includes("?") ? "&" : "?";
  return `${path}${separator}lang=${locale}`;
}
