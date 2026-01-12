# Tidy: Camera Roll Cleaner - MVP Build Spec

## Overview
Build "Tidy: Camera Roll Cleaner" - a privacy-first photo management app that helps users quickly decide which photos to keep or delete using swipe gestures.

## ⚠️ CRITICAL: Privacy & Security Requirements

**This is the #1 priority of the entire application.**

- **100% offline operation** - The app must NEVER connect to the internet for any functionality
- **No analytics, tracking, or telemetry** - Zero data collection of any kind
- **No cloud storage** - All data stays on device only
- **No accounts or sign-up** - Users open the app and start using it immediately
- **No third-party SDKs** that phone home (no Firebase, no Amplitude, no Mixpanel, etc.)
- **Local storage only** - Use on-device storage (UserDefaults, Core Data, or local SQLite) for app state
- **Minimal permissions** - Only request photo library access, nothing else
- **Photos never leave the device** - Never upload, cache externally, or transmit photos anywhere
- **Transparent deletion** - When users delete photos, use the system's "Recently Deleted" folder so they can recover for 30 days

The app should be auditable - if someone looked at the code, they should see zero network calls, zero external dependencies that collect data, and zero ways for user data to leave the device.

---

## Platform
iOS (Swift/SwiftUI) - targeting iOS 16+

---

## Core Features

### 1. Main Swiping Interface
- Display one photo at a time from the user's camera roll
- Three swipe gestures:
  - **Swipe RIGHT** = Keep (photo stays in library, move to next)
  - **Swipe LEFT** = Delete (mark for deletion, move to next)
  - **Swipe UP** = Maybe (save to "decide later" pile, move to next)
- **Undo button** always visible on screen (like Hinge dating app) - tapping it reverses the last swipe decision
- **Tap to zoom** - user can tap a photo to view it fullscreen and pinch to zoom
- **Video playback** - if the item is a video, user can tap to play it within the app
- Progress indicator showing "X of Y" photos reviewed
- Auto-save progress - if user closes app, they resume exactly where they left off

### 2. Smart Grouping (Timestamp-based)
- Detect photos taken within 10 seconds of each other
- Group these as "similar shots"
- Present them together so user can pick the best one
- When user keeps one from a group, optionally prompt "Delete the other X similar photos?"

### 3. Filters
- Small filter icon in the corner (not prominent)
- Filter options:
  - All Photos (default)
  - Screenshots only
  - Last 30 days
  - By year (2024, 2023, etc.)
  - Largest files first
  - Maybe pile (photos swiped up)
- Selecting a filter scopes the swiping session to that subset

### 4. Trash Review
- Before any photos are actually deleted, user reviews them in a scrollable grid
- User is prompted after each swiping session: "You marked X photos for deletion. Review now?"
- User can also access trash review anytime via a button/menu
- From the grid, user can:
  - Tap a photo to view it larger
  - Restore individual photos (move back to "keep")
  - Confirm deletion with "Empty Trash" button
- Emptying trash moves photos to iOS "Recently Deleted" folder (not permanent delete)

### 5. Maybe Pile
- Photos swiped up go to "Maybe" pile
- Accessible via filter menu
- User can swipe through Maybe pile again when ready
- Prompted when main library is fully reviewed: "Ready to tackle your X maybes?"

### 6. Stats Screen
- Shown after emptying trash
- Display prominently:
  - "X.X GB freed"
  - "X photos removed"
  - "X photos reviewed this session"
- Should feel satisfying and celebratory

---

## Data Storage (Local Only)

Store the following using UserDefaults or local database:

```
- currentSessionIndex: Int (where user left off)
- currentFilter: String (active filter)
- markedForDeletion: [String] (photo identifiers)
- maybePile: [String] (photo identifiers)
- reviewedPhotos: [String] (photo identifiers already swiped)
- sessionStats: { photosReviewed: Int, bytesFreed: Int }
```

Use Apple's PhotoKit (PHPhotoLibrary) for all photo access. Never copy photos to app storage - always reference them via PhotoKit identifiers.

---

## UI/UX Design Direction

**Aesthetic: Old library / subtle Renaissance**
- NOT a typical tech app - should feel like a rare book collection or archival museum
- Warm, scholarly, quietly luxurious, timeless

**Reference the included design file: `tidy-design-reference.html`** - This is the exact look we want.

### Exact Color Palette

```swift
// Light Mode
let backgroundLight = Color(hex: "#F5F0E6")  // Warm cream/parchment
let charcoal = Color(hex: "#36322b")          // Primary text
let primary = Color(hex: "#b6890c")           // Antique gold accent
let primaryDark = Color(hex: "#8a6605")       // Darker gold for pressed states

// Dark Mode
let backgroundDark = Color(hex: "#221d10")    // Deep warm brown
let darkModeText = Color(hex: "#e8e1cf")      // Warm off-white
let cardBackgroundDark = Color(hex: "#2a2415") // Card surface in dark mode

// Special Elements
let waxSealRed = Color(hex: "#8B0000")        // Undo button background
let waxSealBorder = Color(hex: "#6d0000")     // Undo button border
```

### Typography

```swift
// Use these Google Fonts or closest iOS equivalents
// Serif: "Newsreader" (or fall back to Georgia)
// Sans-serif: "Inter" (or fall back to SF Pro)

// App title "Tidy" - Newsreader, italic, medium weight, 30pt
// Progress text "124 of 1,832" - Inter, semibold, 11pt, tracking widest, uppercase
// Action labels - Newsreader, italic, 14pt
```

### Background Effects

```swift
// Paper texture - subtle grain overlay at 40% opacity
// Vignette - radial gradient: transparent center (50%) fading to rgba(54, 50, 43, 0.08) at edges
```

### Photo Card Design

```swift
// Card dimensions
let aspectRatio = 3.0 / 4.0  // Portrait orientation
let maxHeight = screenHeight * 0.65  // 65% of screen height max
let cardPadding = 12.0  // 3px equivalent padding inside card for frame effect
let cardCornerRadius = 8.0

// Archival shadow (the key shadow that makes it feel mounted)
// Shadow 1: offset(0, 10), blur 15, color rgba(0,0,0,0.1)
// Shadow 2: offset(0, 4), blur 6, color rgba(0,0,0,0.05)  
// Border: 1px rgba(182, 137, 12, 0.2) - subtle gold tint

// Inner matte effect - 0.5px border inside the photo area, rgba(0,0,0,0.1)

// Stacked cards behind (creates depth):
// Card 1 (furthest back): scale 95%, translateY +3px, opacity 60%
// Card 2 (middle): scale 97.5%, translateY +1.5px, opacity 80%
// Card 3 (front/main): scale 100%, full opacity
```

### Undo Button (Wax Seal Style)

```swift
// This is a key design element - styled like a classical wax seal
let size = 56.0  // 14 * 4 = 56pt
let backgroundColor = Color(hex: "#8B0000")  // Dark red
let borderColor = Color(hex: "#6d0000")
let borderWidth = 2.0

// Shadow for wax seal effect:
// Outer: offset(0, 4), blur 6, rgba(0,0,0,0.2)
// Inner highlight: inset offset(0, 2), blur 4, rgba(255,255,255,0.3)
// Inner shadow: inset offset(0, -2), blur 4, rgba(0,0,0,0.2)

// Icon: SF Symbol "arrow.uturn.backward" rotated -12° by default
// On hover/press: rotate to 0°
// On press: scale to 95%
```

### Swipe Direction Indicators

```swift
// Left side (Delete):
// - Circle: 48pt, border 1px charcoal/20%, background backgroundLight/80% with blur
// - Icon: "xmark" in charcoal/70%
// - Label: "Delete" rotated -90°, serif italic, charcoal/60%
// - Overall opacity: 40%

// Right side (Keep):
// - Circle: 48pt, border 1px primary/30%, background backgroundLight/80% with blur
// - Icon: "heart.fill" in primary color
// - Label: "Keep" rotated +90°, serif italic, primary color
// - Overall opacity: 40%

// Top (Maybe):
// - Icon: "questionmark" in primary/70%
// - Label: "Maybe" uppercase, tracking wide, primary/80%
// - Overall opacity: 60%
```

### Action Labels (Below Photo)

```swift
// Left: trash icon + "Delete" italic - charcoal at 60% opacity, red on hover
// Center: Wax seal undo button (elevated, overlapping slightly into card area)
// Right: "Keep" italic + heart icon - charcoal at 60% opacity, gold on hover
```

### Progress Indicator (Footer)

```swift
// Text: "124 of 1,832" - Inter semibold, 11pt, tracking widest, uppercase, charcoal/60%
// Bar: 200pt max width, 4pt height, rounded full
// Bar background: charcoal/10%
// Bar fill: primary color (gold), animated width transition
```

### Animation Guidelines

```swift
// Card hover: scale to 1.01 over 300ms ease-out
// Card swipe: follow gesture with momentum, ease-out
// Undo button press: scale to 0.95 over 150ms
// Undo icon: rotate from -12° to 0° on hover over 200ms
// Progress bar: width transition 500ms ease-out
// All transitions should feel smooth and unhurried, like turning pages
```

### Layout Structure

```
┌─────────────────────────────────┐
│  [spacer]    Tidy    [filter]   │  ← Header
├─────────────────────────────────┤
│           Maybe ↑               │  ← Top indicator
│                                 │
│  ← Delete  ┌─────────┐  Keep →  │  ← Side indicators
│            │         │          │
│            │  Photo  │          │  ← Main card with stacked cards behind
│            │  Card   │          │
│            │         │          │
│            └─────────┘          │
│                                 │
│   Delete    (undo)      Keep    │  ← Action labels + wax seal button
├─────────────────────────────────┤
│         124 of 1,832            │  ← Progress text
│         ════════────            │  ← Progress bar
└─────────────────────────────────┘
```

---

## Screens to Build

**Design Reference:** See `tidy-design-reference.html` for the exact visual implementation of the main swipe screen. Match this design precisely.

1. **Onboarding/Permission** - Simple screen requesting photo access, explaining privacy commitment
2. **Main Swipe Screen** - The core swiping interface (match the reference HTML exactly)
3. **Photo Detail View** - Fullscreen photo with zoom, video playback
4. **Filter Sheet** - Bottom sheet with filter options
5. **Trash Review Grid** - Grid of photos marked for deletion
6. **Maybe Pile Grid** - Grid of "maybe" photos
7. **Stats/Completion Screen** - Post-deletion celebration
8. **Empty State** - When all photos reviewed

---

## Technical Notes

- Use SwiftUI for UI
- Use PhotoKit (Photos framework) for photo library access
- Use @AppStorage or UserDefaults for persisting state
- Implement proper photo caching for smooth scrolling (but cache locally only)
- Handle permission denied gracefully
- Support both portrait and landscape photos
- Handle Live Photos and videos appropriately
- Test with large libraries (1000+ photos)
- **Support Dark Mode** - The design reference includes dark mode colors, implement system appearance switching

---

## What NOT to Include

- No network code whatsoever
- No analytics or crash reporting SDKs
- No ads
- No in-app purchases (for MVP)
- No account system
- No social sharing
- No cloud backup
- No "pro" upsells

---

## Success Criteria

A user should be able to:
1. Open the app for the first time
2. Grant photo permission
3. Immediately start swiping through photos
4. Close the app and return later, picking up where they left off
5. Review their "trash" pile before deletion
6. Empty trash and see satisfying stats
7. Feel confident that their photos never left their device

The app should feel trustworthy, calm, and private - the opposite of sketchy "cleaner" apps.