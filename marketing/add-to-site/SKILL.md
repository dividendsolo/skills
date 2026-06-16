---
name: add-to-site
description: Use this skill when adding a new project/app to the dividend-solo portfolio site. Reads project details from the project's own repo (under ~/Developer/repos/dividendsolo/<repo>) and updates the portfolio site's ProjectsSection.tsx. Use when the user invokes /add-to-site or says "add this to the site", "add a project to the portfolio".
trigger: /add-to-site
---

# Add Project to Portfolio

Use this skill to add a new app or project to the dividend-solo portfolio at `/Users/james/Developer/repos/dividendsolo/dividend-solo`.

## Step 0 — Classify the project

First determine which kind of entry this is — it changes where `href` and `image` come from:

- **Deployed to production** (has a live URL — custom domain or `*.vercel.app`): `href` is the production URL, `image` is an OG image (see table below).
- **MVP / not deployed** (prototype, local-only, demo-stage): `href` is a **Screen Studio share link** to the demo video — James generates it from his Screen Studio account ("Shareable link" export). Ask him for the link if you don't have it; do NOT host the video file yourself or use a file path. The demo recording workflow lives in the project's `scripts/cursor-demo.ts` (see recall/fieldlog for the pattern).

## Step 1 — Gather project info

You need four things. If the user hasn't provided them, ask:

| Field | Where to find it |
|---|---|
| **name** | The display name (e.g. "EchoForm") |
| **href** | Deployed → production URL (e.g. `https://echo-form.com`). MVP → Screen Studio share link from James (Step 0). |
| **description** | 1–2 sentence summary. If not provided, read the project's CLAUDE.md or README at `~/Developer/repos/dividendsolo/<repo>/` and draft one. |
| **tech** | Key libraries/services. Read `package.json` in the project repo if not provided. |
| **image** | Deployed only: OG image URL. Check if the repo has `app/opengraph-image.tsx` — if so, use `<href>/opengraph-image`. Otherwise check for `public/og.png`. If neither exists, **create `app/opengraph-image.tsx`** in the project repo (see note below) and use the `/opengraph-image` URL. MVP: no deployed origin to serve from — use a screenshot/poster frame committed to dividend-solo's `public/` instead. |

**Description style:** short, punchy, dash-separated clauses. Match the existing entries:
- "Investment portfolio tracker — SEC EDGAR integration, multi-asset support, performance analytics."
- "SEAL training prep — digital workout programs based on the NSW Training Guide, PST tracking, analytics."

**Tech array:** 4–6 items max, most recognizable first (Next.js, then DB, then payments/auth, then extras).

## Step 2 — Add the entry

Edit `/Users/james/Developer/repos/dividendsolo/dividend-solo/components/ProjectsSection.tsx` (project data lives in `lib/projects-data.ts`).

The site has **two project sections**:

1. **Production** — deployed apps with live URLs (the original section).
2. **MVP** — demo-stage builds whose cards link to Screen Studio demo videos. This section carries a "Contact me if interested." message so visitors know these are available to commission/buy.

Put the entry in the section matching its Step 0 classification. (If the MVP section doesn't exist in the codebase yet, build it to mirror the Production section's card grid, plus the contact message linking to the existing contact form.)

Add a new object to the matching projects array, after the last existing entry:

```typescript
{
  name: "<Name>",
  href: "<https://...>",
  description:
    "<One-line summary — key feature, key feature, key feature.>",
  tech: ["Next.js", "<DB>", "<Service>", ...],
  image: "<https://...>/opengraph-image",  // or /og.png if static
},
```

## Step 2b — Create opengraph-image.tsx if missing

If the project repo has no OG image, create `/Users/james/Developer/repos/dividendsolo/<repo>/app/opengraph-image.tsx`:

```tsx
import { ImageResponse } from "next/og"

export const size = { width: 1200, height: 630 }
export const contentType = "image/png"
export const alt = "<AppName> — <tagline>"

export default async function OgImage() {
  return new ImageResponse(
    <div
      style={{
        height: "100%", width: "100%", display: "flex",
        flexDirection: "column", justifyContent: "space-between",
        padding: 80, background: "#0a0a0a", color: "white",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      {/* Logo mark */}
      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        <div style={{
          width: 56, height: 56, borderRadius: 14,
          background: "<brand-color>", display: "flex",
          alignItems: "center", justifyContent: "center",
          fontSize: 32, fontWeight: 800, color: "#0a0a0a",
        }}>
          <AppInitial>
        </div>
        <div style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-0.02em" }}>
          <AppName>
        </div>
      </div>
      {/* Headline */}
      <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
        <div style={{ fontSize: 88, fontWeight: 800, letterSpacing: "-0.04em", lineHeight: 1.0, display: "flex" }}>
          <Line 1>
        </div>
        <div style={{ fontSize: 88, fontWeight: 800, letterSpacing: "-0.04em", lineHeight: 1.0, display: "flex", color: "<brand-color>" }}>
          <Line 2>
        </div>
      </div>
      {/* Footer */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontSize: 26, color: "#a1a1aa", display: "flex" }}>
          <domain> · <tagline>
        </div>
        <div style={{
          display: "flex", gap: 10, background: "<brand-color>", color: "#0a0a0a",
          fontSize: 26, fontWeight: 700, padding: "14px 28px", borderRadius: 999,
        }}>
          <span>Get started</span><span style={{ fontSize: 28 }}>→</span>
        </div>
      </div>
    </div>,
    size,
  )
}
```

Find the brand color in `app/globals.css` (`--primary` variable). Run `bun run typecheck` in that repo after adding.

## Step 3 — Verify

Run the type check and lint to confirm no issues:

```bash
cd /Users/james/Developer/repos/dividendsolo/dividend-solo
bun tsc --noEmit && bun run lint
```

Fix any errors before finishing.

## Step 4 — Update next.config if needed

The portfolio uses `next/image`. If the new project's OG image is hosted on a domain not already in `remotePatterns`, add it.

Check `/Users/james/Developer/repos/dividendsolo/dividend-solo/next.config.ts` — look for the `images.remotePatterns` array. If the new image hostname is missing, add:

```typescript
{ protocol: "https", hostname: "<new-domain>" }
```

## Notes

- Projects are displayed in the order they appear in the array — newest goes last.
- The grid is 2 columns on `sm:` and above, 1 column on mobile.
- Images use `aspect-[1200/630]` — standard OG aspect ratio. Make sure the image URL resolves to a real image before shipping.
- Do NOT ship — wait for the user to run `/shipit`.
