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
      { title: "Review cost", text: "Render confirmation remains account-owned and available only after sign-in." }
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
    mapBody: "The web app carries Animate AV's visual language into a protected creation surface for signed-in rendering.",
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
    body: "Sign in to open creation, videos, and Avi routes. Animate AV web keeps product functionality behind your AV account.",
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
        { title: "Revisa el coste", text: "La confirmación de render sigue siendo de la cuenta y sólo está disponible tras iniciar sesión." }
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
      mapBody: "La web lleva el lenguaje visual de Animate AV a una superficie protegida para render con sesión iniciada.",
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
      body: "Inicia sesión para abrir creación, videos y Avi. Animate AV web mantiene la funcionalidad de producto detrás de tu cuenta AV.",
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
      aviTitle: "Avi garde la scène ciblée",
      items: [
        { label: "Une image", value: "Gardez la scène source au centre" },
        { label: "Style et guide", value: "Façonnez le mouvement avec retenue" },
        { label: "Vidéos", value: "Relisez les créations terminées" }
      ],
      body: "Animate AV transforme une image en courte vidéo animée dans un flux connecté.",
      cta: "Créer une vidéo",
      title: "Animez une image en courte vidéo."
    },
    avi: {
      body: "Avi garde le parcours de création clair : une image source, un style précis, une indication facultative, une relecture et un rendu final quand le flux connecté est disponible.",
      cards: [
        { title: "Gardez une image centrale", text: "Commencez par la photo ou l’image générée qui doit rester la référence visuelle." },
        { title: "Choisissez le style", text: "Utilisez la famille visuelle et le look avant de passer aux indications ou au coût." },
        { title: "Relisez avant le rendu", text: "Les étapes de crédits et de rendu restent derrière le compte." }
      ],
      createCta: "Créer une vidéo",
      galleryCta: "Ouvrir les vidéos",
      title: "Un parcours guidé de l’image vers la vidéo animée."
    },
    create: {
      body: "Préparez une courte vidéo animée à partir d’une image. Le port web protège d’abord la route produit ; l’envoi, les crédits et le rendu restent derrière le backend connecté.",
      cta: "Flux de création protégé",
      flow: [
        { title: "Choisissez une image", text: "Utilisez une seule image source pour garder une référence claire dans le résultat animé." },
        { title: "Choisissez style et guide", text: "Sélectionnez le look et ajoutez une courte indication facultative avant la relecture." },
        { title: "Relisez le coût", text: "La confirmation du rendu reste liée au compte et disponible seulement après connexion." }
      ],
      title: "Créez une vidéo animée à partir d’une image."
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
      mapBody: "L’app web porte le langage visuel d’Animate AV vers une surface protégée pour un rendu connecté.",
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
      body: "Connectez-vous pour ouvrir création, vidéos et Avi. Animate AV web garde les fonctions produit derrière votre compte AV.",
      cta: "Se connecter",
      title: "Vos créations restent derrière votre compte AV."
    },
    gallery: {
      body: "Les créations connectées apparaîtront ici pour relecture, téléchargement et retour lorsque le flux web sera connecté.",
      emptyBody: "Créez une vidéo animée depuis une session connectée et les vidéos terminées seront rassemblées ici.",
      emptyTitle: "Vos vidéos sont prêtes pour la première création.",
      filters: ["Toutes", "En rendu", "Prêtes", "Téléchargées"],
      hints: [
        { title: "Relire", text: "Vérifiez le résultat généré avant de l’enregistrer ou de le partager." },
        { title: "Télécharger", text: "Les vidéos finales sont enregistrées par l’utilisateur lorsqu’elles sont prêtes." },
        { title: "Historique", text: "Les créations terminées restent liées au compte pour un retour plus calme." }
      ],
      kicker: "Vidéos",
      title: "Vos vidéos animées, réunies au même endroit."
    },
    signIn: {
      ...en.signIn,
      aviPanelBody: "Avi garde l’image source et les indications de mouvement alignées.",
      body: "Connectez-vous pour garder l’image source, les options de création, l’état du rendu et les vidéos finales reliés à votre compte AV.",
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
      aviTitle: "Avi hält die Szene fokussiert",
      items: [
        { label: "Ein Bild", value: "Die Ausgangsszene bleibt zentral" },
        { label: "Look und Hinweis", value: "Bewegung kontrolliert formen" },
        { label: "Videos", value: "Fertige Kreationen prüfen" }
      ],
      body: "Animate AV verwandelt ein Bild in einem angemeldeten Ablauf in ein kurzes animiertes Video.",
      cta: "Video erstellen",
      title: "Ein Bild als kurzes Video animieren."
    },
    avi: {
      body: "Avi hält den Erstellungsweg klar: ein Quellbild, ein fokussierter Look, optionale Hinweise, Prüfung und finaler Render, sobald der angemeldete Ablauf verfügbar ist.",
      cards: [
        { title: "Ein Bild zentral halten", text: "Beginne mit dem Foto oder generierten Bild, das die visuelle Referenz bleiben soll." },
        { title: "Den Look wählen", text: "Nutze Stilfamilie und Look, bevor du zu Hinweisen oder Kostenprüfung wechselst." },
        { title: "Vor dem Rendern prüfen", text: "Credits und Render-Schritte bleiben hinter dem Konto." }
      ],
      createCta: "Video erstellen",
      galleryCta: "Videos öffnen",
      title: "Ein geführter Weg vom Bild zum animierten Video."
    },
    create: {
      body: "Bereite aus einem Bild ein kurzes animiertes Video vor. Der Web-Port schützt zuerst die Produktroute; Upload, Credits und Render-Aktionen bleiben hinter der angemeldeten Backend-Anbindung.",
      cta: "Geschützter Erstellungsablauf",
      flow: [
        { title: "Ein Bild wählen", text: "Nutze ein einzelnes Quellbild, damit das animierte Ergebnis eine klare Referenz behält." },
        { title: "Look und Hinweis wählen", text: "Wähle den Look und ergänze optional einen kurzen Hinweis vor der Prüfung." },
        { title: "Kosten prüfen", text: "Die Render-Bestätigung bleibt kontogebunden und ist erst nach Anmeldung verfügbar." }
      ],
      title: "Erstelle ein animiertes Video aus einem Bild."
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
      mapBody: "Die Web-App bringt die visuelle Sprache von Animate AV in eine geschützte Oberfläche für angemeldetes Rendern.",
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
      body: "Melde dich an, um Erstellung, Videos und Avi zu öffnen. Animate AV Web hält Produktfunktionen hinter deinem AV-Konto.",
      cta: "Anmelden",
      title: "Deine Kreationen bleiben hinter deinem AV-Konto."
    },
    gallery: {
      body: "Angemeldete Kreationen erscheinen hier zur Prüfung, zum Download und für spätere Rückkehr, sobald der Web-Ablauf verbunden ist.",
      emptyBody: "Erstelle ein animiertes Video in einer angemeldeten Sitzung; fertige Videos werden hier gesammelt.",
      emptyTitle: "Deine Videos sind bereit für die erste Erstellung.",
      filters: ["Alle", "Rendern", "Bereit", "Heruntergeladen"],
      hints: [
        { title: "Prüfen", text: "Kontrolliere das generierte Ergebnis, bevor du es speicherst oder teilst." },
        { title: "Download", text: "Finale Videos werden gespeichert, wenn sie bereit sind." },
        { title: "Verlauf", text: "Abgeschlossene Kreationen bleiben für eine ruhigere Rückkehr mit dem Konto verbunden." }
      ],
      kicker: "Videos",
      title: "Deine animierten Videos, an einem Ort gesammelt."
    },
    signIn: {
      ...en.signIn,
      aviPanelBody: "Avi hält Quellbild und Bewegungshinweise aufeinander abgestimmt.",
      body: "Melde dich an, um Quellbild, Erstellungsoptionen, Renderstatus und fertige Videos mit deinem AV-Konto zu verbinden.",
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
      aviTitle: "Avi manté enfocada l’escena",
      items: [
        { label: "Una imatge", value: "Mantén central l’escena font" },
        { label: "Look i guia", value: "Dona forma al moviment amb control" },
        { label: "Vídeos", value: "Revisa creacions acabades" }
      ],
      body: "Animate AV converteix una imatge en un vídeo animat curt dins d’un flux amb sessió.",
      cta: "Crea vídeo",
      title: "Anima una imatge en un vídeo curt."
    },
    avi: {
      body: "Avi manté clar el camí de creació: una imatge font, un look enfocat, guia opcional, revisió i render final quan el flux amb sessió estigui disponible.",
      cards: [
        { title: "Mantén una imatge central", text: "Comença amb la foto o imatge generada que ha de continuar sent la referència visual." },
        { title: "Tria el look", text: "Fes servir la família visual i el look abans de passar a guia o revisió de cost." },
        { title: "Revisa abans del render", text: "Els passos de crèdits i render queden darrere del compte." }
      ],
      createCta: "Crea vídeo",
      galleryCta: "Obre vídeos",
      title: "Un camí guiat de la imatge al vídeo animat."
    },
    create: {
      body: "Prepara un vídeo animat curt des d’una imatge. El port web protegeix primer la ruta de producte; pujada, crèdits i render queden darrere del backend amb sessió.",
      cta: "Flux de creació protegit",
      flow: [
        { title: "Tria una imatge", text: "Fes servir una sola imatge font perquè el resultat animat mantingui una referència clara." },
        { title: "Tria look i guia", text: "Selecciona el look i afegeix una guia breu opcional abans de revisar." },
        { title: "Revisa el cost", text: "La confirmació de render continua sent del compte i només està disponible després d’iniciar sessió." }
      ],
      title: "Crea un vídeo animat des d’una imatge."
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
      mapBody: "La web porta el llenguatge visual d’Animate AV a una superfície protegida per al render amb sessió iniciada.",
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
      body: "Inicia sessió per obrir creació, vídeos i Avi. Animate AV web manté la funcionalitat de producte darrere del teu compte AV.",
      cta: "Inicia sessió",
      title: "Les teves creacions queden darrere del teu compte AV."
    },
    gallery: {
      body: "Les creacions amb sessió apareixeran aquí per revisar, descarregar i reprendre quan el flux web estigui connectat.",
      emptyBody: "Crea un vídeo animat amb sessió i els vídeos acabats es reuniran aquí.",
      emptyTitle: "Els teus vídeos estan preparats per a la primera creació.",
      filters: ["Tots", "Renderitzant", "Preparats", "Descarregats"],
      hints: [
        { title: "Revisa", text: "Comprova el resultat generat abans de desar o compartir." },
        { title: "Descarrega", text: "Els vídeos finals es desen quan estan preparats." },
        { title: "Historial", text: "Les creacions acabades continuen unides al compte per tornar-hi amb calma." }
      ],
      kicker: "Vídeos",
      title: "Els teus vídeos animats, reunits en un lloc."
    },
    signIn: {
      ...en.signIn,
      aviPanelBody: "Avi manté alineades la imatge font i la guia de moviment.",
      body: "Inicia sessió per mantenir imatge font, opcions de creació, estat del render i vídeos finals connectats amb el teu compte AV.",
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
