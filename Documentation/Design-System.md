# Design System

The project uses a lightweight design system built on top of SwiftUI, with shared tokens and reusable components.

Primary sources:

- `projectDAM/DesignSystem.swift`
- `projectDAM/Theme/AppColors.swift`
- `projectDAM/Theme/AppAppearance.swift`

---

## Design Principles

- Use **tokens** (spacing, radii, colors) instead of ad-hoc values.
- Prefer **system semantics** (`.primary`, `.secondary`, Dynamic Type) for accessibility.
- Keep brand identity through controlled tokens, not per-screen customization.

---

## Fonts

### Where fonts live

- `TacheLik_iosApp/Fonts/` contains Nunito font files.

### How fonts are registered

Fonts are registered via **Info.plist** using `UIAppFonts`:

- `Nunito-Regular.ttf`
- `Nunito-SemiBold.ttf`
- `Nunito-Bold.ttf`
- `Nunito-ExtraBold.ttf`

### How fonts are used

In SwiftUI:

```swift
Text("TacheLik")
  .font(.custom("Nunito-ExtraBold", size: 48))
```

Guidelines:

- Prefer Dynamic Type for body text when possible.
- Use custom fonts for branding, but keep readability and scaling in mind.

---

## Colors

### Brand colors

Brand colors are defined in `DesignSystem.swift` via `DS.Colors` and `Color.brand*` extensions.

### Light/Dark Mode

The project also defines dynamic colors in `Theme/AppColors.swift` using `UIColor` dynamic providers.

This enables:

- readable surfaces in dark mode
- consistent navigation chrome
- stable contrast for cards, borders, dividers

Example:

- `Color.appSurface`, `Color.appGroupedBackground`

---

## Spacing System

Token examples:

- `DS.paddingXS = 4`
- `DS.paddingSM = 8`
- `DS.paddingMD = 16`
- `DS.paddingLG = 24`
- `DS.paddingXL = 32`

Rule:

- Default to `paddingMD` for container padding.
- Use smaller spacing (`SM`) for dense UI only.

---

## Corner Radius

Tokens:

- `DS.cornerRadiusSM = 8`
- `DS.cornerRadiusMD = 12`
- `DS.cornerRadiusLG = 16`
- `DS.cornerRadiusXL = 20`

---

## Reusable Components

Examples found across the project:

- Button styles: `PrimaryButtonStyle`, `SecondaryButtonStyle`
- Card modifiers: `.cardStyle()` / `.appCardStyle()`
- Loading overlay: `LoadingView`

Reusability rules:

- Components should not depend on feature services.
- Prefer dependency injection via parameters.

---

## Navigation Appearance

Navigation styling is centralized via `AppNavigationContainer` and `appNavigationBarStyle`.

See: [Navigation-and-Routing.md](Navigation-and-Routing.md)

---

## Do / Don’t

Do:

- Use DS tokens.
- Use dynamic colors and semantic text colors.
- Prefer reusable modifiers for surfaces.

Don’t:

- Hardcode colors across multiple screens.
- Use pure black backgrounds that reduce hierarchy.
- Duplicate button styles per feature.
