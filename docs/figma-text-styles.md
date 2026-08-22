# Import text styles from Figma

BOMA can load extra style presets from `assets/figma/text_styles.json`. Those appear in the style picker alongside the built-in presets.

## One-time setup

1. Authenticate the Figma plugin in Cursor (already done if you connected your account).
2. Open your BOMA design file in the **Figma desktop app** (recommended for `use_figma`).

## Sync styles

In Cursor chat, send your Figma file URL, for example:

```text
Export Figma text styles to BOMA
https://www.figma.com/design/FILE_KEY/BOMA?node-id=0-1
```

The agent will:

1. Call `use_figma` with your `fileKey` and list `figma.getLocalTextStylesAsync()`.
2. Write the result to `assets/figma/text_styles.json`.
3. Hot restart the app — new styles show under **All** in the style panel.

## JSON shape

Each entry in `styles` matches the Figma export:

```json
{
  "id": "heading_h1",
  "name": "Heading/H1",
  "displayName": "Large title",
  "fontSize": 32,
  "fontName": { "family": "Vazir", "style": "Bold" },
  "fills": [{ "type": "SOLID", "color": { "r": 1, "g": 1, "b": 1 }, "opacity": 1 }],
  "isPro": false
}
```

Optional fields: `displayName`, `isPro`. Typography comes from Figma text styles; stroke, shadow, and bubble effects still use built-in presets or manual JSON if you add those fields later.

## Notes

- Figma text styles are **typography** (font, size, color). Full effect presets (stroke, neon, bubble) may need separate Figma components or hand-editing in Dart.
- Font families must exist in `pubspec.yaml` under `assets/fonts/`.
