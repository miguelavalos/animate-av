# Animate AV Web App Pattern

Animate AV follows the shared Apps AV web shell pattern while keeping every
credit, upload, render-plan, and provider action behind authenticated product
routes.

## Shell

- All product routes render through `AnimateAppShell`.
- Primary navigation is Home, Create, In Progress, and Videos.
- Avi is exposed through the shared assistant slot, not duplicated as a primary
  navigation item.
- Footer labels and account controls come from the shared Apps AV and Account AV
  packages.

## Public And Protected Routes

- `/` is public and shows product identity, core value, and a compact sign-in
  panel for signed-out users.
- `/sign-in` remains the dedicated Account AV login route.
- `/create`, `/in-progress`, `/gallery`, and `/avi` stay protected.
- The web app must not trigger upload, render plan, credit reservation, or final
  render work from public routes.

## QA

Run these checks before pushing web shell or route changes:

```bash
cd apps/web
vp run typecheck
vp run build:production
vp run qa:shared
```

For browser QA, start the local server with the existing Varlock wrapper:

```bash
cd apps/web
vp run dev --force
```

Then verify `/`, `/sign-in`, `/create`, `/in-progress`, `/gallery`, and `/avi`
in at least Spanish and English. The signed-out protected routes should show the
account gate without exposing render actions.
