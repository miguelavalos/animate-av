import { useMemo } from "react";
import { useAppsAvLocale, type AppsAvLocale, type AppsAvProductConfig, type AppsAvProductLink } from "@avalsys/apps-av-web";
import { caES } from "@clerk/localizations/ca-ES";
import { deDE } from "@clerk/localizations/de-DE";
import { enUS } from "@clerk/localizations/en-US";
import { esES } from "@clerk/localizations/es-ES";
import { frFR } from "@clerk/localizations/fr-FR";
import { animateProductConfig } from "@/lib/animate-config";
import type { AnimateLook, AnimateLookFamilyId } from "@/lib/animate-models";

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
    activeWorkLoading: "Checking active work.",
    activeWorkMany: "active jobs visible here and in In Progress.",
    activeWorkNone: "No active video work is visible.",
    activeWorkOne: "1 active job visible here and in In Progress.",
    activeWorkText: "Open In Progress for realtime work once the approved Convex web runtime is configured.",
    activeWorkTitle: "Active work",
    createCta: "Create video",
    creditAvailable: "credit available for review and render decisions.",
    creditAvailablePlural: "credits available for review and render decisions.",
    creditLoading: "Credit balance is loading. Treat it as unknown, not zero.",
    creditNone: "No spendable credits are available. Use the approved Account AV credits path before rendering.",
    creditsTitle: "Credits",
    galleryCta: "Open videos",
    heroBody: "Guidance is based on account state, credit loading, local downloaded videos, and the approved Create/In Progress/Videos routes.",
    heroTitle: "Avi keeps the current workflow grounded.",
    inProgressCta: "In Progress",
    localVideosTitle: "Local videos",
    localVideoSaved: "downloaded video saved in this browser profile.",
    localVideoSavedPlural: "downloaded videos saved in this browser profile.",
    title: "A guided path from image to animated video."
  },
  config: {
    body: "Run the web app through the Varlock wrapper so Account AV configuration is available. The public home is informational; product routes require login.",
    eyebrow: "Configuration required",
    title: "Animate AV Web needs Clerk configuration."
  },
  errors: {
    authRequired: "Sign in again to continue.",
    creditsUnavailable: "Credits are not available for this render. Open credits and try again.",
    downloadFailed: "Video download could not be prepared.",
    forbidden: "This action is not available for this account.",
    notFound: "This Animate AV item is no longer available.",
    planFailed: "The render plan could not be prepared. Review the setup and try again.",
    realtimeFailed: "Realtime updates could not be started. Local submitted work is still shown when available.",
    requestFailed: "Animate AV request failed.",
    uploadFailed: "The source image upload could not be completed."
  },
  create: {
    body: "Prepare a short animated video from one image. The web port protects the product route first; upload, credit, and render actions stay behind signed-in backend wiring.",
    cta: "Protected creation flow",
    flow: [
      { title: "Choose one image", text: "Use a single source image so the animated result keeps a clear reference." },
      { title: "Pick style and guide", text: "Select the look and add optional short guidance before review." },
      { title: "Review cost", text: "Render confirmation remains account-owned and available only after sign-in." }
    ],
    steps: {
      animation: "Animation",
      look: "Look",
      message: "Message",
      review: "Review",
      source: "Source"
    },
    ui: {
      available: "available",
      blockers: "Blockers",
      canCreate: "Can create",
      checkCost: "Check cost",
      checkingCost: "Checking final video cost.",
      cost: "Cost",
      costUnit: "credit",
      costUnitPlural: "credits",
      createFinalVideo: "Create final video",
      credits: "Credits",
      currentPlan: "Current plan",
      clear: "Clear",
      comingSoon: "Coming soon",
      loading: "Loading",
      missing: "Missing",
      newSetup: "New setup",
      noExtraGuidance: "No extra guidance",
      noImageSelected: "No image selected",
      none: "None",
      noPlanYet: "No plan checked yet.",
      noSpokenMessage: "No message",
      notChecked: "Not checked",
      openCredits: "Open credits",
      pending: "Pending",
      planAuthority: "The plan endpoint is the only source of cost and blockers.",
      planBlockers: "Plan returned blockers.",
      planReady: "Plan ready. Review before creating the final video.",
      prepareUpload: "Prepare upload",
      preparingUpload: "Preparing signed upload.",
      ready: "Ready",
      removalCost: "Removal cost",
      removalSelected: "Removal selected by plan",
      renderPlan: "Render plan",
      reviewCurrentPlan: "Check cost again before creating the final video. The setup changed after this plan was prepared.",
      reviewCreatable: "Review a creatable render plan first.",
      setupSummary: "Setup summary",
      sourceReady: "Source image is ready.",
      standardWatermark: "Standard watermark",
      startFromSourcePhoto: "Start from the source photo",
      submittingFinal: "Submitting final render once.",
      upload: "Upload",
      uploadAgain: "Upload again",
      uploadBeforeCost: "Upload one source image before checking cost.",
      uploadingSource: "Uploading source image.",
      chooseSourceFirst: "Choose one source image first.",
      imageReadFailed: "Selected image could not be read.",
      imageTooLarge: "Choose an image under 25 MB.",
      unsupportedImageType: "Choose a JPG, PNG, HEIC, or WebP image.",
      finalQueued: "Final video is queued. Open In Progress or Videos to continue.",
      queuedTitle: "Final video queued",
      queuedBody: "Track the active render in In Progress. Download it from Videos once the backend exposes the completed artifact.",
      openInProgress: "Open In Progress",
      openVideos: "Open videos",
      frame: "Frame",
      frameApplied: "Portrait frame applied",
      frameFull: "Full image",
      frameHelp: "Full image is the default. Use portrait frame only when you want a centered 9:16 crop before upload.",
      framePortrait: "Portrait frame",
      watermark: "Watermark",
      yes: "Yes",
      no: "No",
      animationPlaceholder: "Example: a small wave, gentle tai chi, subtle smile",
      messagePlaceholder: "Write a short dedication or message",
      requestFailed: "Animate AV request failed."
    },
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
    availabilityPermanent: "Permanent Gallery storage remains local-first after download.",
    availabilityRemote: "Remote recovery: short-lived artifacts can be downloaded again while the backend exposes them.",
    availabilitySaved: "Saved on device: video blob is available in this browser session.",
    availabilityTitle: "Availability model",
    body: "This web gallery is local-first after download. Available backend artifacts are shown only through the approved short-lived realtime projection.",
    createCta: "Create video",
    defaultTitle: "Animate AV video",
    download: "Download",
    emptyBody: "Create a final video, then download an available artifact to keep it in this browser profile.",
    emptyTitle: "No downloaded videos on this device.",
    filters: ["All", "Rendering", "Ready", "Downloaded"],
    hints: [
      { title: "Review", text: "Check the generated result before saving or sharing." },
      { title: "Download", text: "Final videos are saved by the user when they are ready." },
      { title: "History", text: "Completed creations stay tied to the account for a calmer return flow." }
    ],
    kicker: "Videos",
    localFileMissing: "The local video file is not available in this browser. Download the remote artifact again if it is still listed above.",
    localFileMissingBadge: "Local file missing",
    remoteTitle: "Available to download",
    rename: "Rename",
    requestFailed: "Animate AV request failed.",
    save: "Save",
    savedOnDevice: "Saved on this device",
    clearLocal: "Clear local",
    feedbackTitle: "Quick review",
    feedbackFields: {
      lookMatch: "Look/theme",
      sourceLikeness: "Source likeness",
      motionFollowed: "Motion",
      voiceMessage: "Message"
    },
    feedbackScores: {
      good: "Good",
      okay: "Okay",
      bad: "Bad"
    },
    title: "Downloaded Animate AV videos."
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
  inProgress: {
    badge: "In Progress",
    title: "Active Animate AV work.",
    body: "Active jobs are observed through the approved realtime projection when configured. The local list only covers renders this browser submitted.",
    continueCreating: "Continue creating",
    queued: "Queued",
    running: "Running",
    completed: "Completed",
    failed: "Failed",
    canceled: "Canceled",
    finalVideo: "Final video",
    sourceImage: "Source image",
    waiting: "waiting",
    rendering: "rendering",
    ready: "ready",
    loading: "Loading active work",
    emptyTitle: "No active jobs.",
    emptyBody: "Create a final video to see queued and running work here.",
    videos: "Videos",
    rename: "Rename",
    save: "Save",
    delete: "Delete",
    clearLocal: "Clear local",
    defaultTitle: "Animate AV video",
    realtimeTitle: "Realtime status",
    realtimeConfigured: "Convex realtime is configured for this build.",
    realtimeNotConfigured: "Convex realtime is not configured for this build.",
    realtimeSessionActive: "A backend realtime session is active.",
    realtimeSessionInactive: "No realtime session is active.",
    authority: "Credits, blockers, and provider decisions still come only from the Animate API.",
    requestFailed: "Animate AV request failed."
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
    inProgress: "In Progress",
    inProgressLabel: "Open active Animate AV work",
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

export const animateTranslations: Record<AppsAvLocale, AnimateText> = {
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
      activeWorkLoading: "Revisando trabajo activo.",
      activeWorkMany: "trabajos activos visibles aquí y en En curso.",
      activeWorkNone: "No hay trabajo de video activo visible.",
      activeWorkOne: "1 trabajo activo visible aquí y en En curso.",
      activeWorkText: "Abre En curso para ver trabajo realtime cuando el runtime web aprobado de Convex esté configurado.",
      activeWorkTitle: "Trabajo activo",
      createCta: "Crear video",
      creditAvailable: "crédito disponible para decisiones de revisión y render.",
      creditAvailablePlural: "créditos disponibles para decisiones de revisión y render.",
      creditLoading: "El saldo de créditos está cargando. Trátalo como desconocido, no como cero.",
      creditNone: "No hay créditos gastables disponibles. Usa la ruta aprobada de créditos en Account AV antes de renderizar.",
      creditsTitle: "Créditos",
      galleryCta: "Abrir videos",
      heroBody: "La guía se basa en el estado de cuenta, la carga de créditos, los videos descargados localmente y las rutas aprobadas Crear/En curso/Videos.",
      heroTitle: "Avi mantiene asentado el flujo actual.",
      inProgressCta: "En curso",
      localVideosTitle: "Videos locales",
      localVideoSaved: "video descargado guardado en este perfil del navegador.",
      localVideoSavedPlural: "videos descargados guardados en este perfil del navegador.",
      title: "Un camino guiado desde imagen a video animado."
    },
    config: {
      body: "Ejecuta la web con el wrapper de Varlock para que Account AV esté disponible. La home pública es informativa; las rutas de producto requieren login.",
      eyebrow: "Configuración requerida",
      title: "Animate AV Web necesita configuración de Clerk."
    },
    errors: {
      authRequired: "Inicia sesión de nuevo para continuar.",
      creditsUnavailable: "Los créditos no están disponibles para este render. Abre créditos e inténtalo de nuevo.",
      downloadFailed: "No se ha podido preparar la descarga del video.",
      forbidden: "Esta acción no está disponible para esta cuenta.",
      notFound: "Este elemento de Animate AV ya no está disponible.",
      planFailed: "No se ha podido preparar el plan de render. Revisa el ajuste e inténtalo de nuevo.",
      realtimeFailed: "No se han podido iniciar las actualizaciones realtime. El trabajo local enviado se seguirá mostrando cuando esté disponible.",
      requestFailed: "La solicitud de Animate AV ha fallado.",
      uploadFailed: "No se ha podido completar la subida de la imagen fuente."
    },
    create: {
      body: "Prepara un video animado corto desde una imagen. El port web protege primero la ruta de producto; subida, créditos y render quedan detrás del backend con sesión.",
      cta: "Flujo protegido",
      flow: [
        { title: "Elige una imagen", text: "Usa una sola imagen fuente para que el resultado conserve una referencia clara." },
        { title: "Elige look y guía", text: "Selecciona el estilo y añade una guía breve opcional antes de revisar." },
        { title: "Revisa el coste", text: "La confirmación de render sigue siendo de la cuenta y sólo está disponible tras iniciar sesión." }
      ],
      steps: {
        animation: "Animación",
        look: "Look",
        message: "Mensaje",
        review: "Revisión",
        source: "Fuente"
      },
      ui: {
        available: "disponibles",
        blockers: "Bloqueos",
        canCreate: "Puede crear",
        checkCost: "Revisar coste",
        checkingCost: "Revisando el coste del video final.",
        cost: "Coste",
        costUnit: "crédito",
        costUnitPlural: "créditos",
        createFinalVideo: "Crear video final",
        credits: "Créditos",
        currentPlan: "Plan vigente",
        clear: "Borrar",
        comingSoon: "Próximamente",
        loading: "Cargando",
        missing: "Falta",
        newSetup: "Nuevo ajuste",
        noExtraGuidance: "Sin guía extra",
        noImageSelected: "Sin imagen seleccionada",
        none: "Ninguno",
        noPlanYet: "Aún no se ha revisado ningún plan.",
        noSpokenMessage: "Sin mensaje hablado",
        notChecked: "Sin revisar",
        openCredits: "Abrir créditos",
        pending: "Pendiente",
        planAuthority: "El endpoint de plan es la única fuente de coste y bloqueos.",
        planBlockers: "El plan devolvió bloqueos.",
        planReady: "Plan listo. Revisa antes de crear el video final.",
        prepareUpload: "Preparar subida",
        preparingUpload: "Preparando subida firmada.",
        ready: "Listo",
        removalCost: "Coste de retirada",
        removalSelected: "Retirada seleccionada por el plan",
        renderPlan: "Plan de render",
        reviewCurrentPlan: "Revisa el coste de nuevo antes de crear el video final. El ajuste cambió después de preparar este plan.",
        reviewCreatable: "Revisa primero un plan de render creable.",
        setupSummary: "Resumen",
        sourceReady: "La imagen fuente está lista.",
        standardWatermark: "Marca de agua estándar",
        startFromSourcePhoto: "Empezar desde la foto fuente",
        submittingFinal: "Enviando el render final una sola vez.",
        upload: "Subida",
        uploadAgain: "Subir de nuevo",
        uploadBeforeCost: "Sube una imagen fuente antes de revisar el coste.",
        uploadingSource: "Subiendo imagen fuente.",
        chooseSourceFirst: "Elige primero una imagen fuente.",
        imageReadFailed: "No se ha podido leer la imagen seleccionada.",
        imageTooLarge: "Elige una imagen de menos de 25 MB.",
        unsupportedImageType: "Elige una imagen JPG, PNG, HEIC o WebP.",
        finalQueued: "El video final está en cola. Abre En curso o Videos para continuar.",
        queuedTitle: "Video final en cola",
        queuedBody: "Sigue el render activo en En curso. Descárgalo desde Videos cuando el backend exponga el artefacto completado.",
        openInProgress: "Abrir En curso",
        openVideos: "Abrir videos",
        frame: "Encuadre",
        frameApplied: "Encuadre vertical aplicado",
        frameFull: "Imagen completa",
        frameHelp: "La imagen completa es el valor inicial. Usa encuadre vertical sólo si quieres un recorte centrado 9:16 antes de subir.",
        framePortrait: "Encuadre vertical",
        watermark: "Marca de agua",
        yes: "Sí",
        no: "No",
        animationPlaceholder: "Ejemplo: un pequeño saludo, tai chi suave, sonrisa sutil",
        messagePlaceholder: "Escribe una dedicatoria o mensaje breve",
        requestFailed: "La solicitud de Animate AV ha fallado."
      },
      title: "Crea un video animado desde una imagen."
    },
    footer: { deleteAccount: "Eliminar cuenta", language: "Idioma", privacy: "Privacidad", support: "Soporte", terms: "Términos" },
    gallery: {
      availabilityPermanent: "El almacenamiento permanente de la galería sigue siendo local tras la descarga.",
      availabilityRemote: "Recuperación remota: los artefactos temporales pueden descargarse de nuevo mientras el backend los exponga.",
      availabilitySaved: "Guardado en el dispositivo: el blob de video está disponible en esta sesión del navegador.",
      availabilityTitle: "Modelo de disponibilidad",
      body: "Esta galería web es local-first tras la descarga. Los artefactos disponibles del backend sólo se muestran mediante la proyección realtime temporal aprobada.",
      createCta: "Crear video",
      defaultTitle: "Video de Animate AV",
      download: "Descargar",
      emptyBody: "Crea un video final y descarga un artefacto disponible para conservarlo en este perfil del navegador.",
      emptyTitle: "No hay videos descargados en este dispositivo.",
      filters: ["Todos", "Renderizando", "Listos", "Descargados"],
      hints: [
        { title: "Revisar", text: "Comprueba el resultado generado antes de guardar o compartir." },
        { title: "Descargar", text: "Los videos finales se guardan cuando están listos." },
        { title: "Historial", text: "Las creaciones completadas siguen unidas a la cuenta para volver con calma." }
      ],
      kicker: "Videos",
      localFileMissing: "El archivo de video local no está disponible en este navegador. Descarga otra vez el artefacto remoto si aún aparece arriba.",
      localFileMissingBadge: "Falta el archivo local",
      remoteTitle: "Disponibles para descargar",
      rename: "Renombrar",
      requestFailed: "La solicitud de Animate AV ha fallado.",
      save: "Guardar",
      savedOnDevice: "Guardado en este dispositivo",
      clearLocal: "Borrar local",
      feedbackTitle: "Revisión rápida",
      feedbackFields: {
        lookMatch: "Look/theme",
        sourceLikeness: "Parecido fuente",
        motionFollowed: "Movimiento",
        voiceMessage: "Mensaje"
      },
      feedbackScores: {
        good: "Bien",
        okay: "Regular",
        bad: "Mal"
      },
      title: "Videos de Animate AV descargados."
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
    inProgress: {
      badge: "En curso",
      title: "Trabajos activos de Animate AV.",
      body: "Los trabajos activos se observan mediante la proyección realtime aprobada cuando está configurada. La lista local sólo cubre renders enviados desde este navegador.",
      continueCreating: "Seguir creando",
      queued: "En cola",
      running: "En ejecución",
      completed: "Completados",
      failed: "Fallidos",
      canceled: "Cancelados",
      finalVideo: "Video final",
      sourceImage: "Imagen fuente",
      waiting: "en espera",
      rendering: "renderizando",
      ready: "listos",
      loading: "Cargando trabajos activos",
      emptyTitle: "No hay trabajos activos.",
      emptyBody: "Crea un video final para ver aquí trabajos en cola y en ejecución.",
      videos: "Videos",
      rename: "Renombrar",
      save: "Guardar",
      delete: "Eliminar",
      clearLocal: "Borrar local",
      defaultTitle: "Video de Animate AV",
      realtimeTitle: "Estado realtime",
      realtimeConfigured: "Convex realtime está configurado para esta build.",
      realtimeNotConfigured: "Convex realtime no está configurado para esta build.",
      realtimeSessionActive: "Hay una sesión realtime del backend activa.",
      realtimeSessionInactive: "No hay una sesión realtime activa.",
      authority: "Créditos, bloqueos y decisiones de proveedor siguen viniendo sólo de Animate API.",
      requestFailed: "La solicitud de Animate AV ha fallado."
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
      inProgress: "En curso",
      inProgressLabel: "Abrir trabajos activos de Animate AV",
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
    errors: {
      authRequired: "Reconnectez-vous pour continuer.",
      creditsUnavailable: "Les crédits ne sont pas disponibles pour ce rendu. Ouvrez les crédits et réessayez.",
      downloadFailed: "Le téléchargement de la vidéo n’a pas pu être préparé.",
      forbidden: "Cette action n’est pas disponible pour ce compte.",
      notFound: "Cet élément Animate AV n’est plus disponible.",
      planFailed: "Le plan de rendu n’a pas pu être préparé. Relisez la configuration et réessayez.",
      realtimeFailed: "Les mises à jour realtime n’ont pas pu démarrer. Le travail local envoyé reste affiché lorsqu’il est disponible.",
      requestFailed: "La requête Animate AV a échoué.",
      uploadFailed: "L’envoi de l’image source n’a pas pu être terminé."
    },
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
    inProgress: {
      badge: "En cours",
      title: "Travail Animate AV actif.",
      body: "Les tâches actives sont observées via la projection realtime approuvée lorsqu’elle est configurée. La liste locale ne couvre que les rendus envoyés par ce navigateur.",
      continueCreating: "Continuer la création",
      queued: "En file",
      running: "En cours",
      completed: "Terminées",
      failed: "Échouées",
      canceled: "Annulées",
      finalVideo: "Vidéo finale",
      sourceImage: "Image source",
      waiting: "en attente",
      rendering: "en rendu",
      ready: "prêtes",
      loading: "Chargement du travail actif",
      emptyTitle: "Aucune tâche active.",
      emptyBody: "Créez une vidéo finale pour voir ici les tâches en file et en cours.",
      videos: "Vidéos",
      rename: "Renommer",
      save: "Enregistrer",
      delete: "Supprimer",
      clearLocal: "Effacer localement",
      defaultTitle: "Vidéo Animate AV",
      realtimeTitle: "État realtime",
      realtimeConfigured: "Convex realtime est configuré pour cette build.",
      realtimeNotConfigured: "Convex realtime n’est pas configuré pour cette build.",
      realtimeSessionActive: "Une session realtime backend est active.",
      realtimeSessionInactive: "Aucune session realtime n’est active.",
      authority: "Les crédits, blocages et décisions de fournisseur viennent toujours uniquement de l’API Animate.",
      requestFailed: "La requête Animate AV a échoué."
    },
    avi: {
      body: "Avi garde le parcours de création clair : une image source, un style précis, une indication facultative, une relecture et un rendu final quand le flux connecté est disponible.",
      cards: [
        { title: "Gardez une image centrale", text: "Commencez par la photo ou l’image générée qui doit rester la référence visuelle." },
        { title: "Choisissez le style", text: "Utilisez la famille visuelle et le look avant de passer aux indications ou au coût." },
        { title: "Relisez avant le rendu", text: "Les étapes de crédits et de rendu restent derrière le compte." }
      ],
      activeWorkLoading: "Vérification du travail actif.",
      activeWorkMany: "travaux actifs visibles ici et dans En cours.",
      activeWorkNone: "Aucun travail vidéo actif visible.",
      activeWorkOne: "1 travail actif visible ici et dans En cours.",
      activeWorkText: "Ouvrez En cours pour le travail realtime une fois le runtime web Convex approuvé configuré.",
      activeWorkTitle: "Travail actif",
      createCta: "Créer une vidéo",
      creditAvailable: "crédit disponible pour les décisions de relecture et de rendu.",
      creditAvailablePlural: "crédits disponibles pour les décisions de relecture et de rendu.",
      creditLoading: "Le solde de crédits charge. Considérez-le comme inconnu, pas nul.",
      creditNone: "Aucun crédit utilisable n’est disponible. Utilisez le parcours de crédits Account AV approuvé avant le rendu.",
      creditsTitle: "Crédits",
      galleryCta: "Ouvrir les vidéos",
      heroBody: "Les indications s’appuient sur l’état du compte, le chargement des crédits, les vidéos téléchargées localement et les routes approuvées Créer/En cours/Vidéos.",
      heroTitle: "Avi garde le flux actuel cadré.",
      inProgressCta: "En cours",
      localVideosTitle: "Vidéos locales",
      localVideoSaved: "vidéo téléchargée enregistrée dans ce profil de navigateur.",
      localVideoSavedPlural: "vidéos téléchargées enregistrées dans ce profil de navigateur.",
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
      steps: {
        animation: "Animation",
        look: "Style",
        message: "Message",
        review: "Relecture",
        source: "Source"
      },
      ui: {
        available: "disponibles",
        blockers: "Blocages",
        canCreate: "Peut créer",
        checkCost: "Vérifier le coût",
        checkingCost: "Vérification du coût de la vidéo finale.",
        cost: "Coût",
        costUnit: "crédit",
        costUnitPlural: "crédits",
        createFinalVideo: "Créer la vidéo finale",
        credits: "Crédits",
        currentPlan: "Plan actuel",
        clear: "Effacer",
        comingSoon: "Bientôt disponible",
        loading: "Chargement",
        missing: "Manquant",
        newSetup: "Nouvelle configuration",
        noExtraGuidance: "Aucune indication supplémentaire",
        noImageSelected: "Aucune image sélectionnée",
        none: "Aucun",
        noPlanYet: "Aucun plan vérifié pour le moment.",
        noSpokenMessage: "Aucun message parlé",
        notChecked: "Non vérifié",
        openCredits: "Ouvrir les crédits",
        pending: "En attente",
        planAuthority: "L’endpoint de plan est la seule source du coût et des blocages.",
        planBlockers: "Le plan a renvoyé des blocages.",
        planReady: "Plan prêt. Relisez avant de créer la vidéo finale.",
        prepareUpload: "Préparer l’envoi",
        preparingUpload: "Préparation de l’envoi signé.",
        ready: "Prêt",
        removalCost: "Coût de retrait",
        removalSelected: "Retrait sélectionné par le plan",
        renderPlan: "Plan de rendu",
        reviewCurrentPlan: "Vérifiez à nouveau le coût avant de créer la vidéo finale. La configuration a changé après la préparation de ce plan.",
        reviewCreatable: "Relisez d’abord un plan de rendu créable.",
        setupSummary: "Résumé",
        sourceReady: "L’image source est prête.",
        standardWatermark: "Filigrane standard",
        startFromSourcePhoto: "Commencer depuis la photo source",
        submittingFinal: "Envoi du rendu final une seule fois.",
        upload: "Envoi",
        uploadAgain: "Envoyer à nouveau",
        uploadBeforeCost: "Envoyez une image source avant de vérifier le coût.",
        uploadingSource: "Envoi de l’image source.",
        chooseSourceFirst: "Choisissez d’abord une image source.",
        imageReadFailed: "L’image sélectionnée n’a pas pu être lue.",
        imageTooLarge: "Choisissez une image de moins de 25 Mo.",
        unsupportedImageType: "Choisissez une image JPG, PNG, HEIC ou WebP.",
        finalQueued: "La vidéo finale est en file. Ouvrez En cours ou Vidéos pour continuer.",
        queuedTitle: "Vidéo finale en file",
        queuedBody: "Suivez le rendu actif dans En cours. Téléchargez-le depuis Vidéos lorsque le backend expose l’artefact terminé.",
        openInProgress: "Ouvrir En cours",
        openVideos: "Ouvrir les vidéos",
        frame: "Cadrage",
        frameApplied: "Cadrage portrait appliqué",
        frameFull: "Image complète",
        frameHelp: "L’image complète est le réglage par défaut. Utilisez le cadrage portrait seulement pour un recadrage centré 9:16 avant l’envoi.",
        framePortrait: "Cadrage portrait",
        watermark: "Filigrane",
        yes: "Oui",
        no: "Non",
        animationPlaceholder: "Exemple : petit salut, tai chi doux, sourire subtil",
        messagePlaceholder: "Écrivez une courte dédicace ou un message",
        requestFailed: "La requête Animate AV a échoué."
      },
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
      home: "Accueil",
      inProgress: "En cours",
      inProgressLabel: "Ouvrir le travail Animate AV actif"
    },
    protected: {
      body: "Connectez-vous pour ouvrir création, vidéos et Avi. Animate AV web garde les fonctions produit derrière votre compte AV.",
      cta: "Se connecter",
      title: "Vos créations restent derrière votre compte AV."
    },
    gallery: {
      availabilityPermanent: "Le stockage permanent de la galerie reste local-first après téléchargement.",
      availabilityRemote: "Récupération distante : les artefacts temporaires peuvent être téléchargés à nouveau tant que le backend les expose.",
      availabilitySaved: "Enregistré sur l’appareil : le blob vidéo est disponible dans cette session du navigateur.",
      availabilityTitle: "Modèle de disponibilité",
      body: "Cette galerie web est local-first après téléchargement. Les artefacts backend disponibles ne sont affichés que via la projection realtime temporaire approuvée.",
      createCta: "Créer une vidéo",
      defaultTitle: "Vidéo Animate AV",
      download: "Télécharger",
      emptyBody: "Créez une vidéo finale, puis téléchargez un artefact disponible pour le garder dans ce profil de navigateur.",
      emptyTitle: "Aucune vidéo téléchargée sur cet appareil.",
      filters: ["Toutes", "En rendu", "Prêtes", "Téléchargées"],
      hints: [
        { title: "Relire", text: "Vérifiez le résultat généré avant de l’enregistrer ou de le partager." },
        { title: "Télécharger", text: "Les vidéos finales sont enregistrées par l’utilisateur lorsqu’elles sont prêtes." },
        { title: "Historique", text: "Les créations terminées restent liées au compte pour un retour plus calme." }
      ],
      kicker: "Vidéos",
      localFileMissing: "Le fichier vidéo local n’est pas disponible dans ce navigateur. Téléchargez à nouveau l’artefact distant s’il est encore listé ci-dessus.",
      localFileMissingBadge: "Fichier local manquant",
      remoteTitle: "Disponibles au téléchargement",
      rename: "Renommer",
      requestFailed: "La requête Animate AV a échoué.",
      save: "Enregistrer",
      savedOnDevice: "Enregistré sur cet appareil",
      clearLocal: "Effacer localement",
      feedbackTitle: "Avis rapide",
      feedbackFields: {
        lookMatch: "Look/thème",
        sourceLikeness: "Ressemblance",
        motionFollowed: "Mouvement",
        voiceMessage: "Message"
      },
      feedbackScores: {
        good: "Bien",
        okay: "Moyen",
        bad: "Mal"
      },
      title: "Vidéos Animate AV téléchargées."
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
    errors: {
      authRequired: "Melde dich erneut an, um fortzufahren.",
      creditsUnavailable: "Credits sind für diesen Render nicht verfügbar. Öffne Credits und versuche es erneut.",
      downloadFailed: "Der Video-Download konnte nicht vorbereitet werden.",
      forbidden: "Diese Aktion ist für dieses Konto nicht verfügbar.",
      notFound: "Dieses Animate AV Element ist nicht mehr verfügbar.",
      planFailed: "Der Render-Plan konnte nicht vorbereitet werden. Prüfe die Einrichtung und versuche es erneut.",
      realtimeFailed: "Realtime-Aktualisierungen konnten nicht gestartet werden. Lokal gesendete Arbeit wird weiterhin angezeigt, wenn sie verfügbar ist.",
      requestFailed: "Animate AV Anfrage fehlgeschlagen.",
      uploadFailed: "Der Upload des Quellbilds konnte nicht abgeschlossen werden."
    },
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
    inProgress: {
      badge: "In Arbeit",
      title: "Aktive Animate AV Arbeit.",
      body: "Aktive Jobs werden über die freigegebene Realtime-Projektion beobachtet, wenn sie konfiguriert ist. Die lokale Liste enthält nur Render, die dieser Browser gesendet hat.",
      continueCreating: "Weiter erstellen",
      queued: "Wartend",
      running: "Läuft",
      completed: "Fertig",
      failed: "Fehlgeschlagen",
      canceled: "Abgebrochen",
      finalVideo: "Finales Video",
      sourceImage: "Quellbild",
      waiting: "wartend",
      rendering: "rendern",
      ready: "bereit",
      loading: "Aktive Arbeit wird geladen",
      emptyTitle: "Keine aktiven Jobs.",
      emptyBody: "Erstelle ein finales Video, um wartende und laufende Arbeit hier zu sehen.",
      videos: "Videos",
      rename: "Umbenennen",
      save: "Speichern",
      delete: "Löschen",
      clearLocal: "Lokal entfernen",
      defaultTitle: "Animate AV Video",
      realtimeTitle: "Realtime-Status",
      realtimeConfigured: "Convex realtime ist für diesen Build konfiguriert.",
      realtimeNotConfigured: "Convex realtime ist für diesen Build nicht konfiguriert.",
      realtimeSessionActive: "Eine Backend-Realtime-Sitzung ist aktiv.",
      realtimeSessionInactive: "Keine Realtime-Sitzung ist aktiv.",
      authority: "Credits, Blocker und Provider-Entscheidungen kommen weiterhin nur von der Animate API.",
      requestFailed: "Animate AV Anfrage fehlgeschlagen."
    },
    avi: {
      body: "Avi hält den Erstellungsweg klar: ein Quellbild, ein fokussierter Look, optionale Hinweise, Prüfung und finaler Render, sobald der angemeldete Ablauf verfügbar ist.",
      cards: [
        { title: "Ein Bild zentral halten", text: "Beginne mit dem Foto oder generierten Bild, das die visuelle Referenz bleiben soll." },
        { title: "Den Look wählen", text: "Nutze Stilfamilie und Look, bevor du zu Hinweisen oder Kostenprüfung wechselst." },
        { title: "Vor dem Rendern prüfen", text: "Credits und Render-Schritte bleiben hinter dem Konto." }
      ],
      activeWorkLoading: "Aktive Arbeit wird geprüft.",
      activeWorkMany: "aktive Jobs hier und in In Arbeit sichtbar.",
      activeWorkNone: "Keine aktive Videoarbeit sichtbar.",
      activeWorkOne: "1 aktiver Job hier und in In Arbeit sichtbar.",
      activeWorkText: "Öffne In Arbeit für Realtime-Arbeit, sobald die freigegebene Convex-Webruntime konfiguriert ist.",
      activeWorkTitle: "Aktive Arbeit",
      createCta: "Video erstellen",
      creditAvailable: "Credit für Prüfung und Render-Entscheidungen verfügbar.",
      creditAvailablePlural: "Credits für Prüfung und Render-Entscheidungen verfügbar.",
      creditLoading: "Das Credit-Guthaben lädt. Behandle es als unbekannt, nicht als null.",
      creditNone: "Es sind keine ausgebbaren Credits verfügbar. Nutze vor dem Rendern den freigegebenen Account AV Credits-Pfad.",
      creditsTitle: "Credits",
      galleryCta: "Videos öffnen",
      heroBody: "Die Hinweise basieren auf Kontostatus, Credit-Ladestand, lokal heruntergeladenen Videos und den freigegebenen Routen Erstellen/In Arbeit/Videos.",
      heroTitle: "Avi hält den aktuellen Ablauf geordnet.",
      inProgressCta: "In Arbeit",
      localVideosTitle: "Lokale Videos",
      localVideoSaved: "heruntergeladenes Video in diesem Browserprofil gespeichert.",
      localVideoSavedPlural: "heruntergeladene Videos in diesem Browserprofil gespeichert.",
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
      steps: {
        animation: "Animation",
        look: "Look",
        message: "Nachricht",
        review: "Prüfung",
        source: "Quelle"
      },
      ui: {
        available: "verfügbar",
        blockers: "Blocker",
        canCreate: "Kann erstellen",
        checkCost: "Kosten prüfen",
        checkingCost: "Kosten des finalen Videos werden geprüft.",
        cost: "Kosten",
        costUnit: "Credit",
        costUnitPlural: "Credits",
        createFinalVideo: "Finales Video erstellen",
        credits: "Credits",
        currentPlan: "Aktueller Plan",
        clear: "Leeren",
        comingSoon: "Demnächst",
        loading: "Lädt",
        missing: "Fehlt",
        newSetup: "Neu einrichten",
        noExtraGuidance: "Keine zusätzlichen Hinweise",
        noImageSelected: "Kein Bild ausgewählt",
        none: "Keine",
        noPlanYet: "Noch kein Plan geprüft.",
        noSpokenMessage: "Keine gesprochene Nachricht",
        notChecked: "Nicht geprüft",
        openCredits: "Credits öffnen",
        pending: "Ausstehend",
        planAuthority: "Der Plan-Endpunkt ist die einzige Quelle für Kosten und Blocker.",
        planBlockers: "Der Plan hat Blocker zurückgegeben.",
        planReady: "Plan bereit. Vor dem finalen Video prüfen.",
        prepareUpload: "Upload vorbereiten",
        preparingUpload: "Signierten Upload vorbereiten.",
        ready: "Bereit",
        removalCost: "Entfernungskosten",
        removalSelected: "Entfernung vom Plan ausgewählt",
        renderPlan: "Render-Plan",
        reviewCurrentPlan: "Prüfe die Kosten erneut, bevor du das finale Video erstellst. Die Einrichtung wurde nach diesem Plan geändert.",
        reviewCreatable: "Prüfe zuerst einen erstellbaren Render-Plan.",
        setupSummary: "Zusammenfassung",
        sourceReady: "Quellbild ist bereit.",
        standardWatermark: "Standard-Wasserzeichen",
        startFromSourcePhoto: "Mit dem Quellfoto beginnen",
        submittingFinal: "Finaler Render wird einmal gesendet.",
        upload: "Upload",
        uploadAgain: "Erneut hochladen",
        uploadBeforeCost: "Lade ein Quellbild hoch, bevor du Kosten prüfst.",
        uploadingSource: "Quellbild wird hochgeladen.",
        chooseSourceFirst: "Wähle zuerst ein Quellbild.",
        imageReadFailed: "Das ausgewählte Bild konnte nicht gelesen werden.",
        imageTooLarge: "Wähle ein Bild unter 25 MB.",
        unsupportedImageType: "Wähle ein JPG-, PNG-, HEIC- oder WebP-Bild.",
        finalQueued: "Das finale Video ist in der Warteschlange. Öffne In Arbeit oder Videos, um fortzufahren.",
        queuedTitle: "Finales Video wartet",
        queuedBody: "Verfolge den aktiven Render unter In Arbeit. Lade ihn aus Videos herunter, sobald das Backend das fertige Artefakt bereitstellt.",
        openInProgress: "In Arbeit öffnen",
        openVideos: "Videos öffnen",
        frame: "Ausschnitt",
        frameApplied: "Porträt-Ausschnitt angewendet",
        frameFull: "Ganzes Bild",
        frameHelp: "Das ganze Bild ist Standard. Nutze den Porträt-Ausschnitt nur für einen zentrierten 9:16-Zuschnitt vor dem Upload.",
        framePortrait: "Porträt-Ausschnitt",
        watermark: "Wasserzeichen",
        yes: "Ja",
        no: "Nein",
        animationPlaceholder: "Beispiel: kleines Winken, sanftes Tai Chi, dezentes Lächeln",
        messagePlaceholder: "Schreibe eine kurze Widmung oder Nachricht",
        requestFailed: "Animate AV Anfrage fehlgeschlagen."
      },
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
      home: "Start",
      inProgress: "In Arbeit",
      inProgressLabel: "Aktive Animate AV Arbeit öffnen"
    },
    protected: {
      body: "Melde dich an, um Erstellung, Videos und Avi zu öffnen. Animate AV Web hält Produktfunktionen hinter deinem AV-Konto.",
      cta: "Anmelden",
      title: "Deine Kreationen bleiben hinter deinem AV-Konto."
    },
    gallery: {
      availabilityPermanent: "Der dauerhafte Galerie-Speicher bleibt nach dem Download local-first.",
      availabilityRemote: "Remote-Wiederherstellung: kurzlebige Artefakte können erneut heruntergeladen werden, solange das Backend sie bereitstellt.",
      availabilitySaved: "Auf dem Gerät gespeichert: Der Video-Blob ist in dieser Browser-Sitzung verfügbar.",
      availabilityTitle: "Verfügbarkeitsmodell",
      body: "Diese Web-Galerie ist nach dem Download local-first. Verfügbare Backend-Artefakte werden nur über die freigegebene kurzlebige Realtime-Projektion angezeigt.",
      createCta: "Video erstellen",
      defaultTitle: "Animate AV Video",
      download: "Herunterladen",
      emptyBody: "Erstelle ein finales Video und lade dann ein verfügbares Artefakt herunter, um es in diesem Browserprofil zu behalten.",
      emptyTitle: "Keine heruntergeladenen Videos auf diesem Gerät.",
      filters: ["Alle", "Rendern", "Bereit", "Heruntergeladen"],
      hints: [
        { title: "Prüfen", text: "Kontrolliere das generierte Ergebnis, bevor du es speicherst oder teilst." },
        { title: "Download", text: "Finale Videos werden gespeichert, wenn sie bereit sind." },
        { title: "Verlauf", text: "Abgeschlossene Kreationen bleiben für eine ruhigere Rückkehr mit dem Konto verbunden." }
      ],
      kicker: "Videos",
      localFileMissing: "Die lokale Videodatei ist in diesem Browser nicht verfügbar. Lade das Remote-Artefakt erneut herunter, wenn es oben noch aufgeführt ist.",
      localFileMissingBadge: "Lokale Datei fehlt",
      remoteTitle: "Zum Download verfügbar",
      rename: "Umbenennen",
      requestFailed: "Animate AV Anfrage fehlgeschlagen.",
      save: "Speichern",
      savedOnDevice: "Auf diesem Gerät gespeichert",
      clearLocal: "Lokal entfernen",
      feedbackTitle: "Kurzbewertung",
      feedbackFields: {
        lookMatch: "Look/Theme",
        sourceLikeness: "Quellähnlichkeit",
        motionFollowed: "Bewegung",
        voiceMessage: "Text"
      },
      feedbackScores: {
        good: "Gut",
        okay: "Okay",
        bad: "Schlecht"
      },
      title: "Heruntergeladene Animate AV Videos."
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
    errors: {
      authRequired: "Torna a iniciar sessió per continuar.",
      creditsUnavailable: "Els crèdits no estan disponibles per a aquest render. Obre crèdits i torna-ho a provar.",
      downloadFailed: "No s'ha pogut preparar la descàrrega del vídeo.",
      forbidden: "Aquesta acció no està disponible per a aquest compte.",
      notFound: "Aquest element d'Animate AV ja no està disponible.",
      planFailed: "No s'ha pogut preparar el pla de render. Revisa l'ajust i torna-ho a provar.",
      realtimeFailed: "No s'han pogut iniciar les actualitzacions realtime. El treball local enviat es continuarà mostrant quan estigui disponible.",
      requestFailed: "La sol·licitud d'Animate AV ha fallat.",
      uploadFailed: "No s'ha pogut completar la pujada de la imatge font."
    },
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
    inProgress: {
      badge: "En curs",
      title: "Treballs actius d'Animate AV.",
      body: "Els treballs actius s'observen mitjançant la projecció realtime aprovada quan està configurada. La llista local només cobreix renders enviats des d'aquest navegador.",
      continueCreating: "Continua creant",
      queued: "En cua",
      running: "En execució",
      completed: "Completats",
      failed: "Fallits",
      canceled: "Cancel·lats",
      finalVideo: "Vídeo final",
      sourceImage: "Imatge font",
      waiting: "en espera",
      rendering: "renderitzant",
      ready: "preparats",
      loading: "Carregant treballs actius",
      emptyTitle: "No hi ha treballs actius.",
      emptyBody: "Crea un vídeo final per veure aquí treballs en cua i en execució.",
      videos: "Vídeos",
      rename: "Canvia el nom",
      save: "Desa",
      delete: "Elimina",
      clearLocal: "Esborra local",
      defaultTitle: "Vídeo d'Animate AV",
      realtimeTitle: "Estat realtime",
      realtimeConfigured: "Convex realtime està configurat per a aquesta build.",
      realtimeNotConfigured: "Convex realtime no està configurat per a aquesta build.",
      realtimeSessionActive: "Hi ha una sessió realtime del backend activa.",
      realtimeSessionInactive: "No hi ha cap sessió realtime activa.",
      authority: "Crèdits, bloquejos i decisions de proveïdor continuen venint només de l'API Animate.",
      requestFailed: "La sol·licitud d'Animate AV ha fallat."
    },
    avi: {
      body: "Avi manté clar el camí de creació: una imatge font, un look enfocat, guia opcional, revisió i render final quan el flux amb sessió estigui disponible.",
      cards: [
        { title: "Mantén una imatge central", text: "Comença amb la foto o imatge generada que ha de continuar sent la referència visual." },
        { title: "Tria el look", text: "Fes servir la família visual i el look abans de passar a guia o revisió de cost." },
        { title: "Revisa abans del render", text: "Els passos de crèdits i render queden darrere del compte." }
      ],
      activeWorkLoading: "Revisant treball actiu.",
      activeWorkMany: "treballs actius visibles aquí i a En curs.",
      activeWorkNone: "No hi ha treball de vídeo actiu visible.",
      activeWorkOne: "1 treball actiu visible aquí i a En curs.",
      activeWorkText: "Obre En curs per veure treball realtime quan el runtime web aprovat de Convex estigui configurat.",
      activeWorkTitle: "Treball actiu",
      createCta: "Crea vídeo",
      creditAvailable: "crèdit disponible per a decisions de revisió i render.",
      creditAvailablePlural: "crèdits disponibles per a decisions de revisió i render.",
      creditLoading: "El saldo de crèdits s'està carregant. Tracta'l com a desconegut, no com a zero.",
      creditNone: "No hi ha crèdits gastables disponibles. Fes servir la ruta aprovada de crèdits d'Account AV abans de renderitzar.",
      creditsTitle: "Crèdits",
      galleryCta: "Obre vídeos",
      heroBody: "La guia es basa en l'estat del compte, la càrrega de crèdits, els vídeos descarregats localment i les rutes aprovades Crea/En curs/Vídeos.",
      heroTitle: "Avi manté assentat el flux actual.",
      inProgressCta: "En curs",
      localVideosTitle: "Vídeos locals",
      localVideoSaved: "vídeo descarregat desat en aquest perfil del navegador.",
      localVideoSavedPlural: "vídeos descarregats desats en aquest perfil del navegador.",
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
      steps: {
        animation: "Animació",
        look: "Look",
        message: "Missatge",
        review: "Revisió",
        source: "Font"
      },
      ui: {
        available: "disponibles",
        blockers: "Bloquejos",
        canCreate: "Pot crear",
        checkCost: "Revisa el cost",
        checkingCost: "Revisant el cost del vídeo final.",
        cost: "Cost",
        costUnit: "crèdit",
        costUnitPlural: "crèdits",
        createFinalVideo: "Crea el vídeo final",
        credits: "Crèdits",
        currentPlan: "Pla vigent",
        clear: "Esborra",
        comingSoon: "Properament",
        loading: "Carregant",
        missing: "Falta",
        newSetup: "Nou ajust",
        noExtraGuidance: "Sense guia extra",
        noImageSelected: "Cap imatge seleccionada",
        none: "Cap",
        noPlanYet: "Encara no s'ha revisat cap pla.",
        noSpokenMessage: "Sense missatge parlat",
        notChecked: "No revisat",
        openCredits: "Obre crèdits",
        pending: "Pendent",
        planAuthority: "L'endpoint de pla és l'única font del cost i els bloquejos.",
        planBlockers: "El pla ha retornat bloquejos.",
        planReady: "Pla preparat. Revisa abans de crear el vídeo final.",
        prepareUpload: "Prepara la pujada",
        preparingUpload: "Preparant pujada signada.",
        ready: "Preparat",
        removalCost: "Cost de retirada",
        removalSelected: "Retirada seleccionada pel pla",
        renderPlan: "Pla de render",
        reviewCurrentPlan: "Revisa el cost de nou abans de crear el vídeo final. L'ajust ha canviat després de preparar aquest pla.",
        reviewCreatable: "Revisa primer un pla de render creable.",
        setupSummary: "Resum",
        sourceReady: "La imatge font està preparada.",
        standardWatermark: "Marca d'aigua estàndard",
        startFromSourcePhoto: "Comença des de la foto font",
        submittingFinal: "Enviant el render final una sola vegada.",
        upload: "Pujada",
        uploadAgain: "Puja de nou",
        uploadBeforeCost: "Puja una imatge font abans de revisar el cost.",
        uploadingSource: "Pujant imatge font.",
        chooseSourceFirst: "Tria primer una imatge font.",
        imageReadFailed: "No s'ha pogut llegir la imatge seleccionada.",
        imageTooLarge: "Tria una imatge de menys de 25 MB.",
        unsupportedImageType: "Tria una imatge JPG, PNG, HEIC o WebP.",
        finalQueued: "El vídeo final és a la cua. Obre En curs o Vídeos per continuar.",
        queuedTitle: "Vídeo final a la cua",
        queuedBody: "Segueix el render actiu a En curs. Descarrega'l des de Vídeos quan el backend exposi l'artefacte completat.",
        openInProgress: "Obre En curs",
        openVideos: "Obre vídeos",
        frame: "Enquadrament",
        frameApplied: "Enquadrament vertical aplicat",
        frameFull: "Imatge completa",
        frameHelp: "La imatge completa és el valor inicial. Fes servir enquadrament vertical només si vols un retall centrat 9:16 abans de pujar.",
        framePortrait: "Enquadrament vertical",
        watermark: "Marca d'aigua",
        yes: "Sí",
        no: "No",
        animationPlaceholder: "Exemple: una petita salutació, tai-txi suau, somriure subtil",
        messagePlaceholder: "Escriu una dedicatòria o missatge breu",
        requestFailed: "La sol·licitud d'Animate AV ha fallat."
      },
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
      home: "Inici",
      inProgress: "En curs",
      inProgressLabel: "Obre els treballs actius d'Animate AV"
    },
    protected: {
      body: "Inicia sessió per obrir creació, vídeos i Avi. Animate AV web manté la funcionalitat de producte darrere del teu compte AV.",
      cta: "Inicia sessió",
      title: "Les teves creacions queden darrere del teu compte AV."
    },
    gallery: {
      availabilityPermanent: "L'emmagatzematge permanent de la galeria continua sent local-first després de la descàrrega.",
      availabilityRemote: "Recuperació remota: els artefactes temporals es poden tornar a descarregar mentre el backend els exposi.",
      availabilitySaved: "Desat al dispositiu: el blob de vídeo està disponible en aquesta sessió del navegador.",
      availabilityTitle: "Model de disponibilitat",
      body: "Aquesta galeria web és local-first després de la descàrrega. Els artefactes disponibles del backend només es mostren mitjançant la projecció realtime temporal aprovada.",
      createCta: "Crea vídeo",
      defaultTitle: "Vídeo d'Animate AV",
      download: "Descarrega",
      emptyBody: "Crea un vídeo final i descarrega un artefacte disponible per conservar-lo en aquest perfil del navegador.",
      emptyTitle: "No hi ha vídeos descarregats en aquest dispositiu.",
      filters: ["Tots", "Renderitzant", "Preparats", "Descarregats"],
      hints: [
        { title: "Revisa", text: "Comprova el resultat generat abans de desar o compartir." },
        { title: "Descarrega", text: "Els vídeos finals es desen quan estan preparats." },
        { title: "Historial", text: "Les creacions acabades continuen unides al compte per tornar-hi amb calma." }
      ],
      kicker: "Vídeos",
      localFileMissing: "El fitxer de vídeo local no està disponible en aquest navegador. Torna a descarregar l'artefacte remot si encara apareix a dalt.",
      localFileMissingBadge: "Falta el fitxer local",
      remoteTitle: "Disponibles per descarregar",
      rename: "Canvia el nom",
      requestFailed: "La sol·licitud d'Animate AV ha fallat.",
      save: "Desa",
      savedOnDevice: "Desat en aquest dispositiu",
      clearLocal: "Esborra local",
      feedbackTitle: "Revisió ràpida",
      feedbackFields: {
        lookMatch: "Look/theme",
        sourceLikeness: "Semblança font",
        motionFollowed: "Moviment",
        voiceMessage: "Missatge"
      },
      feedbackScores: {
        good: "Bé",
        okay: "Regular",
        bad: "Mal"
      },
      title: "Vídeos d'Animate AV descarregats."
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

type LookFamilyCopy = Record<AnimateLookFamilyId, { title: string; subtitle: string }>;
type LookTitleCopy = Record<AnimateLook, string>;

const lookFamiliesByLocale: Record<AppsAvLocale, LookFamilyCopy> = {
  en: {
    popular: { title: "Popular", subtitle: "Core animated styles." },
    cuteSocial: { title: "Cute social", subtitle: "Friendly compact characters." },
    comicsInk: { title: "Comics and ink", subtitle: "Panels, linework, and contrast." },
    animeManga: { title: "Anime and manga", subtitle: "Expressive anime variants." },
    paintedHandmade: { title: "Painted handmade", subtitle: "Traditional media texture." },
    digitalGame: { title: "Digital game", subtitle: "Graphic and game-inspired worlds." },
    fantasyWorlds: { title: "Fantasy worlds", subtitle: "Adventure and genre scenes." },
    craftTexture: { title: "Craft texture", subtitle: "Physical material charm." }
  },
  es: {
    popular: { title: "Populares", subtitle: "Estilos animados esenciales." },
    cuteSocial: { title: "Cute social", subtitle: "Personajes cercanos y compactos." },
    comicsInk: { title: "Cómic y tinta", subtitle: "Viñetas, línea y contraste." },
    animeManga: { title: "Anime y manga", subtitle: "Variantes anime expresivas." },
    paintedHandmade: { title: "Pintado a mano", subtitle: "Textura de medios tradicionales." },
    digitalGame: { title: "Digital y juego", subtitle: "Mundos gráficos e inspirados en juegos." },
    fantasyWorlds: { title: "Mundos fantásticos", subtitle: "Escenas de aventura y género." },
    craftTexture: { title: "Textura artesanal", subtitle: "Encanto de materiales físicos." }
  },
  fr: {
    popular: { title: "Populaires", subtitle: "Styles animés essentiels." },
    cuteSocial: { title: "Cute social", subtitle: "Personnages compacts et chaleureux." },
    comicsInk: { title: "BD et encre", subtitle: "Cases, traits et contraste." },
    animeManga: { title: "Anime et manga", subtitle: "Variantes anime expressives." },
    paintedHandmade: { title: "Peint à la main", subtitle: "Texture de médias traditionnels." },
    digitalGame: { title: "Numérique et jeu", subtitle: "Mondes graphiques inspirés du jeu." },
    fantasyWorlds: { title: "Mondes fantastiques", subtitle: "Scènes d'aventure et de genre." },
    craftTexture: { title: "Texture artisanale", subtitle: "Charme de matériaux physiques." }
  },
  de: {
    popular: { title: "Beliebt", subtitle: "Zentrale Animationsstile." },
    cuteSocial: { title: "Cute social", subtitle: "Freundliche kompakte Figuren." },
    comicsInk: { title: "Comic und Tusche", subtitle: "Panels, Linienarbeit und Kontrast." },
    animeManga: { title: "Anime und Manga", subtitle: "Ausdrucksstarke Anime-Varianten." },
    paintedHandmade: { title: "Handgemalt", subtitle: "Textur traditioneller Medien." },
    digitalGame: { title: "Digital und Spiel", subtitle: "Grafische, spielinspirierte Welten." },
    fantasyWorlds: { title: "Fantasiewelten", subtitle: "Abenteuer- und Genreszenen." },
    craftTexture: { title: "Basteltextur", subtitle: "Charme physischer Materialien." }
  },
  ca: {
    popular: { title: "Populars", subtitle: "Estils animats essencials." },
    cuteSocial: { title: "Cute social", subtitle: "Personatges propers i compactes." },
    comicsInk: { title: "Còmic i tinta", subtitle: "Vinyetes, línia i contrast." },
    animeManga: { title: "Anime i manga", subtitle: "Variants anime expressives." },
    paintedHandmade: { title: "Pintat a mà", subtitle: "Textura de mitjans tradicionals." },
    digitalGame: { title: "Digital i joc", subtitle: "Mons gràfics inspirats en jocs." },
    fantasyWorlds: { title: "Mons fantàstics", subtitle: "Escenes d'aventura i gènere." },
    craftTexture: { title: "Textura artesanal", subtitle: "Encant de materials físics." }
  }
};

const lookTitlesEn: LookTitleCopy = {
  acrylicPoster: "Acrylic poster",
  americanComic: "American comic",
  animeWatercolor: "Anime watercolor",
  anime: "Anime",
  blackWhiteManga: "Black and white manga",
  cardboardTheater: "Cardboard theater",
  cartoon: "Cartoon",
  charcoal: "Charcoal",
  chibi: "Chibi",
  cinematic3d: "Cinematic 3D",
  clay: "Clay",
  collageCutout: "Collage cutout",
  comic: "Comic",
  cozySliceOfLife: "Cozy slice of life",
  crayonKids: "Crayon kids",
  cyberAnime: "Cyber anime",
  darkFantasy: "Dark fantasy",
  editorialCaricature: "Editorial caricature",
  embroideredTextile: "Embroidered textile",
  euroComic: "Euro comic",
  fairytale: "Fairytale",
  feltCraft: "Felt craft",
  fantasyQuest: "Fantasy quest",
  flatVector: "Flat vector",
  glitchArt: "Glitch art",
  graphicNovel: "Graphic novel",
  heroicComic: "Heroic comic",
  inkMarker: "Ink marker",
  inkWash: "Ink wash",
  isometricGame: "Isometric game",
  kawaiiPop: "Kawaii pop",
  lowPoly: "Low poly",
  magicalFantasyAnime: "Magical fantasy anime",
  manga: "Manga",
  miniAvatar: "Mini avatar",
  mythicEpic: "Mythic epic",
  neon: "Neon",
  noirInk: "Noir ink",
  oilPainting: "Oil painting",
  origami: "Origami",
  paperCut: "Paper cut",
  pastelDream: "Pastel dream",
  pencilSketch: "Pencil sketch",
  pirateStory: "Pirate story",
  pixel: "Pixel",
  plush: "Plush",
  rubberHose: "Rubber hose",
  sciFiSpace: "Sci-fi space",
  shonenAction: "Shonen action",
  shojoRomance: "Shojo romance",
  soft3d: "Soft 3D",
  sticker: "Sticker",
  stopMotion: "Stop motion",
  storybook: "Storybook",
  stainedGlass: "Stained glass",
  steampunk: "Steampunk",
  sundayStrip: "Sunday strip",
  superDeformed: "Super deformed",
  synthwave: "Synthwave",
  toyFigure: "Toy figure",
  vintagePoster: "Vintage poster",
  voxelWorld: "Voxel world",
  watercolor: "Watercolor",
  yellowComedy: "Yellow comedy"
};

const lookTitlesByLocale: Record<AppsAvLocale, LookTitleCopy> = {
  en: lookTitlesEn,
  es: {
    ...lookTitlesEn,
    acrylicPoster: "Póster acrílico",
    americanComic: "Cómic americano",
    animeWatercolor: "Anime acuarela",
    blackWhiteManga: "Manga en blanco y negro",
    cardboardTheater: "Teatro de cartón",
    cartoon: "Dibujo animado",
    charcoal: "Carboncillo",
    cinematic3d: "3D cinematográfico",
    clay: "Plastilina",
    collageCutout: "Collage recortado",
    cozySliceOfLife: "Vida cotidiana acogedora",
    crayonKids: "Ceras infantiles",
    darkFantasy: "Fantasía oscura",
    editorialCaricature: "Caricatura editorial",
    embroideredTextile: "Textil bordado",
    fairytale: "Cuento de hadas",
    feltCraft: "Fieltro artesanal",
    fantasyQuest: "Misión fantástica",
    flatVector: "Vector plano",
    graphicNovel: "Novela gráfica",
    heroicComic: "Cómic heroico",
    inkMarker: "Tinta y rotulador",
    inkWash: "Lavado de tinta",
    isometricGame: "Juego isométrico",
    lowPoly: "Bajo poligonaje",
    magicalFantasyAnime: "Anime de fantasía mágica",
    miniAvatar: "Mini avatar",
    mythicEpic: "Épica mítica",
    noirInk: "Tinta noir",
    oilPainting: "Óleo",
    paperCut: "Papel recortado",
    pastelDream: "Sueño pastel",
    pencilSketch: "Boceto a lápiz",
    pirateStory: "Historia pirata",
    plush: "Peluche",
    rubberHose: "Animación clásica",
    sciFiSpace: "Espacio sci-fi",
    shonenAction: "Acción shonen",
    shojoRomance: "Romance shojo",
    soft3d: "3D suave",
    stopMotion: "Stop motion",
    storybook: "Libro ilustrado",
    stainedGlass: "Vidriera",
    sundayStrip: "Tira dominical",
    superDeformed: "Super deformed",
    toyFigure: "Figura de juguete",
    vintagePoster: "Póster vintage",
    voxelWorld: "Mundo voxel",
    watercolor: "Acuarela",
    yellowComedy: "Comedia amarilla"
  },
  fr: {
    ...lookTitlesEn,
    acrylicPoster: "Affiche acrylique",
    americanComic: "Comic américain",
    animeWatercolor: "Anime aquarelle",
    blackWhiteManga: "Manga noir et blanc",
    cardboardTheater: "Théâtre en carton",
    cartoon: "Dessin animé",
    charcoal: "Fusain",
    cinematic3d: "3D cinématique",
    clay: "Argile",
    collageCutout: "Collage découpé",
    cozySliceOfLife: "Tranche de vie douce",
    crayonKids: "Crayons d'enfant",
    darkFantasy: "Dark fantasy",
    editorialCaricature: "Caricature éditoriale",
    embroideredTextile: "Textile brodé",
    fairytale: "Conte de fées",
    feltCraft: "Feutrine artisanale",
    fantasyQuest: "Quête fantastique",
    flatVector: "Vecteur plat",
    graphicNovel: "Roman graphique",
    heroicComic: "Comic héroïque",
    inkMarker: "Encre et marqueur",
    inkWash: "Lavis d'encre",
    isometricGame: "Jeu isométrique",
    lowPoly: "Low poly",
    magicalFantasyAnime: "Anime fantasy magique",
    miniAvatar: "Mini avatar",
    mythicEpic: "Épopée mythique",
    noirInk: "Encre noir",
    oilPainting: "Peinture à l'huile",
    paperCut: "Papier découpé",
    pastelDream: "Rêve pastel",
    pencilSketch: "Croquis au crayon",
    pirateStory: "Histoire pirate",
    plush: "Peluche",
    rubberHose: "Animation classique",
    sciFiSpace: "Espace sci-fi",
    shonenAction: "Action shonen",
    shojoRomance: "Romance shojo",
    soft3d: "3D douce",
    stopMotion: "Stop motion",
    storybook: "Livre illustré",
    stainedGlass: "Vitrail",
    sundayStrip: "Strip du dimanche",
    superDeformed: "Super deformed",
    toyFigure: "Figurine",
    vintagePoster: "Affiche vintage",
    voxelWorld: "Monde voxel",
    watercolor: "Aquarelle",
    yellowComedy: "Comédie jaune"
  },
  de: {
    ...lookTitlesEn,
    acrylicPoster: "Acrylposter",
    americanComic: "Amerikanischer Comic",
    animeWatercolor: "Anime-Aquarell",
    blackWhiteManga: "Schwarz-Weiss-Manga",
    cardboardTheater: "Papptheater",
    cartoon: "Cartoon",
    charcoal: "Kohlezeichnung",
    cinematic3d: "Cineastisches 3D",
    clay: "Knete",
    collageCutout: "Collage-Ausschnitt",
    cozySliceOfLife: "Gemütlicher Alltag",
    crayonKids: "Kinderwachsmalstift",
    darkFantasy: "Dunkle Fantasy",
    editorialCaricature: "Editorial-Karikatur",
    embroideredTextile: "Bestickter Stoff",
    fairytale: "Märchen",
    feltCraft: "Filzhandwerk",
    fantasyQuest: "Fantasy-Quest",
    flatVector: "Flacher Vektor",
    graphicNovel: "Graphic Novel",
    heroicComic: "Heroischer Comic",
    inkMarker: "Tusche und Marker",
    inkWash: "Tuschelavierung",
    isometricGame: "Isometrisches Spiel",
    lowPoly: "Low Poly",
    magicalFantasyAnime: "Magischer Fantasy-Anime",
    miniAvatar: "Mini-Avatar",
    mythicEpic: "Mythisches Epos",
    noirInk: "Noir-Tusche",
    oilPainting: "Ölgemälde",
    paperCut: "Papierschnitt",
    pastelDream: "Pastelltraum",
    pencilSketch: "Bleistiftskizze",
    pirateStory: "Piratengeschichte",
    plush: "Plüsch",
    rubberHose: "Klassische Animation",
    sciFiSpace: "Sci-fi-Weltraum",
    shonenAction: "Shonen-Action",
    shojoRomance: "Shojo-Romantik",
    soft3d: "Weiches 3D",
    stopMotion: "Stop Motion",
    storybook: "Bilderbuch",
    stainedGlass: "Buntglas",
    sundayStrip: "Sonntagsstrip",
    superDeformed: "Super deformed",
    toyFigure: "Spielfigur",
    vintagePoster: "Vintage-Poster",
    voxelWorld: "Voxel-Welt",
    watercolor: "Aquarell",
    yellowComedy: "Gelbe Komödie"
  },
  ca: {
    ...lookTitlesEn,
    acrylicPoster: "Pòster acrílic",
    americanComic: "Còmic americà",
    animeWatercolor: "Anime aquarel·la",
    blackWhiteManga: "Manga en blanc i negre",
    cardboardTheater: "Teatre de cartó",
    cartoon: "Dibuix animat",
    charcoal: "Carbonet",
    cinematic3d: "3D cinematogràfic",
    clay: "Plastilina",
    collageCutout: "Collage retallat",
    cozySliceOfLife: "Vida quotidiana acollidora",
    crayonKids: "Ceres infantils",
    darkFantasy: "Fantasia fosca",
    editorialCaricature: "Caricatura editorial",
    embroideredTextile: "Tèxtil brodat",
    fairytale: "Conte de fades",
    feltCraft: "Feltre artesanal",
    fantasyQuest: "Missió fantàstica",
    flatVector: "Vector pla",
    graphicNovel: "Novel·la gràfica",
    heroicComic: "Còmic heroic",
    inkMarker: "Tinta i retolador",
    inkWash: "Rentat de tinta",
    isometricGame: "Joc isomètric",
    lowPoly: "Baix poligonatge",
    magicalFantasyAnime: "Anime de fantasia màgica",
    miniAvatar: "Mini avatar",
    mythicEpic: "Èpica mítica",
    noirInk: "Tinta noir",
    oilPainting: "Oli",
    paperCut: "Paper retallat",
    pastelDream: "Somni pastel",
    pencilSketch: "Esbós a llapis",
    pirateStory: "Història pirata",
    plush: "Peluix",
    rubberHose: "Animació clàssica",
    sciFiSpace: "Espai sci-fi",
    shonenAction: "Acció shonen",
    shojoRomance: "Romanç shojo",
    soft3d: "3D suau",
    stopMotion: "Stop motion",
    storybook: "Llibre il·lustrat",
    stainedGlass: "Vitrall",
    sundayStrip: "Tira dominical",
    superDeformed: "Super deformed",
    toyFigure: "Figura de joguina",
    vintagePoster: "Pòster vintage",
    voxelWorld: "Món voxel",
    watercolor: "Aquarel·la",
    yellowComedy: "Comèdia groga"
  }
};

export function useAnimateText() {
  return animateTranslations[useAppsAvLocale()];
}

export function getAnimateLookTitle(look: AnimateLook, locale: AppsAvLocale) {
  return lookTitlesByLocale[locale][look];
}

export function getAnimateLookFamilyCopy(familyId: AnimateLookFamilyId, locale: AppsAvLocale) {
  return lookFamiliesByLocale[locale][familyId];
}

export function useAnimateLookCopy() {
  const locale = useAppsAvLocale();
  return {
    families: lookFamiliesByLocale[locale],
    titles: lookTitlesByLocale[locale]
  };
}

export function useAnimateAccountLocalization() {
  const locale = useAppsAvLocale();
  const text = animateTranslations[locale];
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
    { href: localizedAppPath("/in-progress", locale), label: text.nav.inProgress },
    { href: localizedAppPath("/gallery", locale), label: text.nav.gallery }
  ];
}

export function useAnimateProductConfig(): AppsAvProductConfig {
  const locale = useAppsAvLocale();
  const text = useAnimateText();

  return useMemo(() => ({
    ...animateProductConfig,
    links: Object.fromEntries(
      Object.entries(animateProductConfig.links).map(([key, link]) => [
        key,
        link ? { ...link, href: localizedExternalUrl(link.href, locale) } : link
      ])
    ) as AppsAvProductConfig["links"],
    assistant: animateProductConfig.assistant
      ? {
        ...animateProductConfig.assistant,
        href: localizedAppPath(animateProductConfig.assistant.href, locale),
        label: text.nav.aviLabel
      }
      : undefined
  }), [locale, text.nav.aviLabel]);
}

function localizedExternalUrl(href: string, locale: AppsAvLocale) {
  if (locale === "en") return href;

  try {
    const url = new URL(href);
    const path = url.pathname === "/" ? "" : url.pathname.replace(/^\/(en|es|fr|de|ca)(?=\/|$)/, "");
    url.pathname = `/${locale}${path}`;
    return url.toString().replace(/\/$/, "");
  } catch {
    return href;
  }
}

export function localizedAppPath(path: string, locale: AppsAvLocale): string {
  const hashIndex = path.indexOf("#");
  const pathWithoutHash = hashIndex >= 0 ? path.slice(0, hashIndex) : path;
  const hash = hashIndex >= 0 ? path.slice(hashIndex + 1) : "";
  const [pathname, query = ""] = pathWithoutHash.split("?", 2);
  const params = new URLSearchParams(query);
  params.delete("lang");

  if (locale !== "en") {
    params.set("lang", locale);
  }

  const nextQuery = params.toString();
  return `${pathname}${nextQuery ? `?${nextQuery}` : ""}${hash ? `#${hash}` : ""}`;
}
