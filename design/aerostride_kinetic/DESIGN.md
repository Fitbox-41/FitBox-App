---
name: Aerostride Kinetic
colors:
  surface: '#101417'
  surface-dim: '#101417'
  surface-bright: '#363a3d'
  surface-container-lowest: '#0b0f11'
  surface-container-low: '#191c1f'
  surface-container: '#1d2023'
  surface-container-high: '#272a2d'
  surface-container-highest: '#323538'
  on-surface: '#e0e2e6'
  on-surface-variant: '#e7bdb8'
  inverse-surface: '#e0e2e6'
  inverse-on-surface: '#2d3134'
  outline: '#ae8883'
  outline-variant: '#5d3f3c'
  surface-tint: '#ffb4ab'
  primary: '#ffb4ab'
  on-primary: '#690006'
  primary-container: '#e31e24'
  on-primary-container: '#fffafa'
  inverse-primary: '#c00014'
  secondary: '#c8c6c8'
  on-secondary: '#303032'
  secondary-container: '#474649'
  on-secondary-container: '#b6b4b7'
  tertiary: '#62dd96'
  on-tertiary: '#00391e'
  tertiary-container: '#00854e'
  on-tertiary-container: '#f0fff1'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb4ab'
  on-primary-fixed: '#410002'
  on-primary-fixed-variant: '#93000d'
  secondary-fixed: '#e4e2e4'
  secondary-fixed-dim: '#c8c6c8'
  on-secondary-fixed: '#1b1b1d'
  on-secondary-fixed-variant: '#474649'
  tertiary-fixed: '#80fab0'
  tertiary-fixed-dim: '#62dd96'
  on-tertiary-fixed: '#00210f'
  on-tertiary-fixed-variant: '#00522e'
  background: '#101417'
  on-background: '#e0e2e6'
  surface-variant: '#323538'
typography:
  display-italic:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 52px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  data-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 42px
    fontWeight: '700'
    lineHeight: 42px
    letterSpacing: -0.02em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 24px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
The design system is engineered for a high-performance territory-capture and fitness experience. It draws inspiration from premium athletic wear and precision instrumentation, blending **Apple-inspired Materiality** with a **Dynamic Kinetic** aesthetic.

The brand personality is authoritative yet energizing—think of a high-end stopwatch or a performance vehicle cockpit. The visual language utilizes heavy italics to imply forward momentum and speed, paired with generous negative space to maintain a "quiet" premium feel. The interface should feel like a physical object: heavy, responsive, and alive with subtle light play.

## Colors
The palette is centered on high-contrast energy. 

- **Primary Energy:** Signature Red (#E31E24) is used for active states, primary actions, and progress. Deep Red (#B3141A) is reserved for gradient steps to provide dimension.
- **Surface Strategy:** In Dark Mode, surfaces utilize a deep vertical gradient. A soft, low-opacity red radial glow (5-10% opacity) should be positioned behind primary data clusters to simulate "engine heat."
- **Functional Colors:** Use #19A463 for positive credit increments (gain) and #E5484D for debits or loss of territory.
- **Typography Contrast:** Use pure White (#FFFFFF) for primary headers on dark, and Charcoal (#2E2E30) for primary headers on light.

## Typography
The typography system prioritizes legibility at high speeds. 

1. **The Kinetic Italic:** Use Hanken Grotesk in Bold Italic for main headers to reinforce the "forward-leaning" brand identity.
2. **Data-Heavy Metrics:** For step counts, territory percentages, and timers, use Plus Jakarta Sans. Its rounded terminals provide a modern, Apple Fitness-style friendliness that balances the aggressive red accents.
3. **Hierarchy:** Secondary information uses Inter to ensure high functional utility and a systematic feel. 
4. **Layout:** All labels should use increased letter spacing when set in uppercase to maintain a premium, technical appearance.

## Layout & Spacing
This design system follows a strict **8pt Grid System**. 

- **Margins:** Standard mobile screen margins are set to 24px to give the "Frosted Glass" cards room to breathe and show off their corner radii.
- **Negative Space:** Use generous vertical stacking (32px+) between distinct content groups (e.g., between the map view and the stats dashboard) to maintain a "Quiet" luxury feel.
- **Alignment:** Data points should be center-aligned within cards but left-aligned in list views to maintain a balance between "dashboard" aesthetics and "utility" aesthetics.

## Elevation & Depth
Depth is achieved through **iOS-style Materiality** rather than traditional drop shadows.

- **Frosted Glass (Backdrop Blur):** All cards must use a `backdrop-filter: blur(20px)`. In Dark Mode, the fill is `rgba(46, 46, 48, 0.7)`. In Light Mode, the fill is `rgba(255, 255, 255, 0.6)`.
- **Inner Borders (The Hairline):** Apply a 1px solid border to all cards. Use `rgba(255, 255, 255, 0.2)` for top/left edges to simulate a light source from the top-left.
- **Shadows:** Use a single, very soft ambient shadow: `0px 10px 30px rgba(0, 0, 0, 0.15)`.
- **Vibrancy:** Foreground text on glass elements should use "vibrancy" effects (overlay or soft light blend modes) to allow the background colors to bleed through slightly, enhancing the premium feel.

## Shapes
The shape language is dominated by **Large Radii** and **Pills**.

- **Cards:** Use a 24px (`rounded-xl`) corner radius for all main containers and glass modules.
- **Interactive Elements:** Buttons and input fields should utilize a fully rounded "Pill" shape to contrast against the structured grid.
- **Progress Indicators:** Use circular geometry for fitness rings to mirror the circularity of the Earth/territory capture icons.

## Components

### Buttons
- **Primary:** Signature Red pill, white text, subtle inner glow on the top half. Use a spring animation (`stiffness: 300, damping: 20`) on tap.
- **Secondary:** Glass-material pill with 1px white hairline border.

### Cards
- Standard modules with 24px radius and backdrop blur. Headlines inside cards should be tucked into the top-left with a 16px padding.

### Tab Bar
- A floating, detached glass pill at the bottom of the screen. Icons should use "Vibrant" white when inactive and Signature Red when active.

### Progress Rings
- 8px stroke width. The background track should be the surface color (#2E2E30) with 20% opacity. The active track uses a gradient from Deep Red to Signature Red.

### Input Fields
- Underlined or subtle glass-fill pills. Focus states are indicated by the 1px border increasing in opacity and a faint red outer glow.

### Territory Indicators
- Small circular chips with a pulse animation to indicate "Contested" or "Active" capture zones. Use #19A463 for captured zones and #E31E24 for lost/hostile zones.