# 🎬 Splash Screen Visual Reference

## Animation Sequence

### Frame-by-Frame Animation

```
┌─────────────────────────────────────────────────────────┐
│  T I M E L I N E   O F   A N I M A T I O N S           │
└─────────────────────────────────────────────────────────┘

TIME: 0ms ════════════════════════════════════════════════════
│
│  STATE:
│  • Logo Scale: 4.0 (HUGE)
│  • Logo Opacity: 0.7 (semi-transparent)
│  • Logo Rotation: -45° (tilted)
│  • Logo Y Position: -400px (off top)
│  • Text Opacity: 0.0 (invisible)
│
├─ ANIMATION: Logo Primary (800ms, easeInOut) ─────────────
│  • Scale: 4.0 → 0.7 ↓
│  • Y Position: -400 → 0 ↓
│  • Rotation: -45° → 0° ↓
│  • Opacity: 0.7 → 1.0 ↑
│
TIME: 800ms ════════════════════════════════════════════════
│
│  STATE:
│  • Logo Scale: 0.7
│  • Logo Opacity: 1.0
│  • Logo Rotation: 0°
│  • Logo Y Position: 0
│  • Text Opacity: 0.0
│
├─ ANIMATION: Logo Bounce (240ms total) ─────────────────
│  Phase 1 (120ms, easeInOut):
│  • Scale: 0.7 → 0.65 ↓
│  
│  Phase 2 (120ms, easeInOut):
│  • Scale: 0.65 → 0.7 ↑
│
TIME: 1020ms ═══════════════════════════════════════════════
│
│  STATE:
│  • Logo Scale: 0.7 (stable)
│  • Logo Opacity: 1.0
│  • Text Opacity: 0.0
│
├─ PAUSE: 100ms ──────────────────────────────────────────
│
TIME: 1120ms ═══════════════════════════════════════════════
│
├─ ANIMATION: Text Fade (420ms, easeInOut) ──────────────
│  • Text Opacity: 0.0 → 1.0 ↑
│  • Logo remains stable
│
TIME: 1540ms ═══════════════════════════════════════════════
│
│  STATE: Final
│  • Logo Scale: 0.7 (centered, stable)
│  • Logo Opacity: 1.0 (fully visible)
│  • Text Opacity: 1.0 (fully visible)
│
├─ PAUSE: 1000ms ─────────────────────────────────────────
│  Hold splash screen in final state
│
TIME: 2540ms ═══════════════════════════════════════════════
│
├─ ANIMATION: Dismiss Fade (300ms, easeInOut) ───────────
│  • Splash Opacity: 1.0 → 0.0 ↓
│  • Reveal main app behind
│
TIME: 2840ms ═══════════════════════════════════════════════
│
│  COMPLETE: Main app now visible
│
└─────────────────────────────────────────────────────────────
```

---

## Color Scheme

### Splash Text Colors

```
┌─────────────────────────────────────────┐
│   T A C H E - L I K                     │
│                                         │
│  "T"         = #DD5746                  │
│  (Orange/Red)                           │
│  RGB: (222, 87, 70)                     │
│                                         │
│  "ache-lik"  = #17A2B8                  │
│  (Cyan)                                 │
│  RGB: (23, 162, 184)                    │
└─────────────────────────────────────────┘
```

### Background
- System background (adapts to light/dark mode)

---

## Layout Specification

### Vertical Layout

```
┌────────────────────────────────────────┐
│                                        │
│                                        │ ↑ Safe Area
│                                        │
│          ┌──────────────┐              │
│          │              │              │
│          │   [LOGO]     │              │ Y Offset: -400px (start)
│          │    100x100   │              │ Y Offset: 0px (end)
│          │              │              │
│          └──────────────┘              │
│                                        │
│          ┌──────────────┐              │
│          │  Tache-lik   │              │
│          │   (70pt)     │              │
│          └──────────────┘              │
│                                        │
│                                        │ ↓ Safe Area
│                                        │
└────────────────────────────────────────┘
```

### Font Rendering

```
T A C H E - L I K
↑                ↑
Orange/Red      Cyan
#DD5746         #17A2B8

Font Family: Nunito
Font Weight: Bold
Font Size: 70pt
Line Height: Auto
```

---

## Animation Easing Curves

### All Animations Use easeInOut

```
Speed over Time (easeInOut):

     ▲
     │     ╱╲
     │    ╱  ╲
     │   ╱    ╲
     │  ╱      ╲
     │ ╱        ╲
     │╱          ╲
     └────────────────► Time

Characteristics:
• Slow start (accelerating)
• Peak speed in middle
• Slow end (decelerating)
• Smooth, natural feel
```

---

## State Transitions

### Logo Animations

```
Scale Transformation:
4.0 ──────────► 0.7 (scale down, zoom in)
     800ms

Rotation Transformation:
-45° ────────► 0° (unrotate, straighten)
     800ms

Position Transformation:
Y: -400px ───► 0px (move from top to center)
     800ms

Opacity Transformation:
0.7 ──────────► 1.0 (fade in)
    800ms
```

### Bounce Effect

```
Scale Oscillation:
0.7 ──► 0.65 ──► 0.7
  120ms    120ms

Creates elastic "pop" effect when logo lands
```

### Text Fade

```
Opacity Transformation:
0.0 ──────────► 1.0 (fade in completely)
    420ms

Happens after 320ms delay from logo settle
```

---

## Device Adaptations

### Screen Size Handling

```
iPhone SE (Small):        iPhone 14 Pro (Large):
┌────────────────┐        ┌──────────────────────┐
│                │        │                      │
│    [LOGO]      │        │        [LOGO]        │
│  100x100pt     │        │      100x100pt       │
│                │        │                      │
│  Tache-lik     │        │    Tache-lik         │
│   70pt font    │        │     70pt font        │
│                │        │                      │
│                │        │                      │
└────────────────┘        └──────────────────────┘

Logo & text scale proportionally with screen
```

### Dark Mode

```
Light Mode:                Dark Mode:
┌─────────────────┐       ┌─────────────────┐
│ Background:     │       │ Background:     │
│ Light Gray      │       │ Dark Gray       │
│ #FFFFFF (approx)│       │ #1C1C1E (approx)│
│                 │       │                 │
│ Text visible    │       │ Text visible    │
│ with same       │       │ with same       │
│ colors          │       │ colors          │
└─────────────────┘       └─────────────────┘
```

---

## Component Hierarchy

```
SplashView
│
├── ZStack
│   │
│   ├── Color(.systemBackground)
│   │   └── ignoresSafeArea()
│   │
│   └── VStack
│       │
│       ├── Image("tache_lik_logo")
│       │   ├── scaleEffect(logoScale)
│       │   ├── opacity(logoOpacity)
│       │   ├── rotationEffect(logoRotation)
│       │   ├── offset(y: logoOffsetY)
│       │   └── shadow(radius: 16)
│       │
│       └── HStack
│           │
│           ├── Text("T")
│           │   ├── foregroundColor(#DD5746)
│           │   └── opacity(textOpacity)
│           │
│           └── Text("ache-lik")
│               ├── foregroundColor(#17A2B8)
│               └── opacity(textOpacity)
│
└── .onAppear
    └── startAnimation()
```

---

## Animation Triggers

```
App Launch
    ↓
projectDAMApp appears
    ↓
showSplash = true
    ↓
SplashView rendered
    ↓
.onAppear triggered
    ↓
startAnimation() called
    ↓
800ms: Logo animates in and rotates
    ↓
920ms: Logo bounces (scale pulse)
    ↓
1120ms: Text fades in
    ↓
2540ms: onSplashComplete() callback
    ↓
showSplash = false (fade transition)
    ↓
Main app revealed
```

---

## Performance Metrics

### Timeline Summary

| Phase | Duration | Operation |
|-------|----------|-----------|
| Logo Primary | 800ms | Scale + Rotate + Translate + Fade |
| Logo Bounce | 240ms | Scale pulse (2x 120ms) |
| Pause | 100ms | Wait before text |
| Text Fade | 420ms | Opacity transition |
| Final Hold | 1000ms | Display splash |
| Dismiss | 300ms | Fade transition |
| **TOTAL** | **2840ms** | Full splash cycle |

### Frame Rate
- Smooth 60fps animations (with easeInOut)
- No janky transitions
- No frame drops

---

## Code Structure

### SplashView.swift Organization

```
SplashView
├── @State Variables
│   ├── logoScale
│   ├── logoOpacity
│   ├── logoRotation
│   ├── logoOffsetY
│   └── textOpacity
│
├── UI Layout (var body)
│   ├── Background ZStack
│   ├── Logo VStack
│   │   ├── Image
│   │   └── HStack (Text)
│   └── .onAppear
│
└── startAnimation()
    ├── Main animation (800ms)
    ├── Bounce sequence (240ms)
    ├── Text fade (420ms)
    └── Completion trigger (2540ms)
```

---

## Visual States

### State 1: Initial (t=0ms)

```
╔════════════════════════╗
║                        ║
║                        ║
║           ╱╲╱╲╱╲╱╲╱╲  ║ ← Logo (small, rotated, faint)
║          ╱            ║
║         ╱              ║
║        ╱               ║
║       ╱                ║
║                        ║
║                        ║
║                        ║
║                        ║
╚════════════════════════╝

Logo: Rotated -45°, Scale 4.0, Opacity 0.7
Text: Invisible
```

### State 2: Logo Landed (t=800ms)

```
╔════════════════════════╗
║                        ║
║                        ║
║         ┌──────┐       ║
║         │      │       ║
║         │ [LOGO]       ║
║         │      │       ║
║         └──────┘       ║
║                        ║
║                        ║
║                        ║
║                        ║
╚════════════════════════╝

Logo: Centered, Scale 0.7, Opacity 1.0
Text: Invisible
```

### State 3: Final (t=1540ms+)

```
╔════════════════════════╗
║                        ║
║         ┌──────┐       ║
║         │      │       ║
║         │ [LOGO]       ║
║         │      │       ║
║         └──────┘       ║
║                        ║
║     Tache-lik          ║ ← Text visible in Nunito-Bold
║                        ║
║                        ║
╚════════════════════════╝

Logo: Centered, Scale 0.7, Opacity 1.0
Text: Centered, Opacity 1.0
```

---

## Customization Reference

### Easy to Modify

```swift
// Logo Size (px)
.frame(width: 100, height: 100)  // Try: 80-120

// Logo Shadow
.shadow(radius: 16)  // Try: 8-24

// Logo Scale Endpoint
logoScale = 0.7  // Try: 0.5-0.9

// Text Size (pt)
size: 70  // Try: 48-96

// Text Colors
Color(red: 0.867, green: 0.341, blue: 0.275)  // Try your brand colors
Color(red: 0.090, green: 0.635, blue: 0.722)

// Animation Durations
duration: 0.8   // Try: 0.5-1.2
duration: 0.12  // Try: 0.08-0.16
duration: 0.42  // Try: 0.3-0.6
```

---

## Browser-Like Flow Chart

```
┌─────────────┐
│ App Launch  │
└──────┬──────┘
       ↓
┌─────────────────────────┐
│ Show Splash Screen      │
│ showSplash = true       │
└──────┬──────────────────┘
       ↓
┌─────────────────────────┐
│ SplashView.onAppear()   │
│ startAnimation()        │
└──────┬──────────────────┘
       ↓
┌─────────────────────────┐
│ Logo animates (800ms)   │
│ • Scale: 4.0 → 0.7     │
│ • Rotate: -45° → 0°    │
│ • Move: -400 → 0       │
│ • Fade: 0.7 → 1.0      │
└──────┬──────────────────┘
       ↓
┌─────────────────────────┐
│ Logo bounces (240ms)    │
│ • Scale pulse effect    │
│ • Creates impact feel   │
└──────┬──────────────────┘
       ↓
┌─────────────────────────┐
│ Text fades in (420ms)   │
│ • "Tache-lik" appears   │
│ • Opacity: 0 → 1.0     │
└──────┬──────────────────┘
       ↓
┌─────────────────────────┐
│ Hold final state (1s)   │
│ • All animations done   │
│ • Splash fully visible  │
└──────┬──────────────────┘
       ↓
┌─────────────────────────┐
│ Dismiss splash (300ms)  │
│ • Fade out animation    │
│ • showSplash = false    │
└──────┬──────────────────┘
       ↓
┌─────────────┐
│ Show Main   │
│ App Content │
└─────────────┘
```

---

## Testing Points

```
✓ Check Logo Appearance
  • Size: 100x100
  • Position: Centered
  • Rotation: Correct direction
  • Shadow: Visible

✓ Check Animations
  • Scale: Smooth zoom
  • Rotation: 45° arc
  • Movement: Vertical
  • Opacity: Fade effect

✓ Check Text
  • Font: Nunito-Bold
  • Colors: Correct
  • Positioning: Centered below logo
  • Timing: After logo settled

✓ Check Timing
  • Total: 2.54 seconds
  • Each phase: Correct duration
  • Smooth transitions
  • No stuttering

✓ Check Modes
  • Light mode: Visible contrast
  • Dark mode: Visible contrast
  • Different devices: Proportional
```

---

**Visual Reference Complete!** 🎨

Use this guide to understand and customize your splash screen animations.
