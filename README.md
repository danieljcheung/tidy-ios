# Tidy: Camera Roll Cleaner

A privacy-first iOS photo management app that helps you quickly decide which photos to keep or delete using intuitive swipe gestures. Designed with a beautiful, old-library aesthetic that makes photo cleanup feel calm and satisfying.

![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Privacy First

**Your photos never leave your device.** This is the core principle of Tidy.

- **100% Offline** - No internet connection required or used
- **No Analytics** - Zero tracking, telemetry, or data collection
- **No Cloud Storage** - All data stays on your device
- **No Accounts** - Open the app and start using it immediately
- **No Third-Party SDKs** - No Firebase, Amplitude, or any external services
- **Transparent Deletion** - Deleted photos go to iOS's Recently Deleted folder (recoverable for 30 days)

The codebase is fully auditable - you'll find zero network calls and zero ways for your data to leave your device.

## Features

### Swipe to Decide
- **Swipe Right** → Keep (photo stays in library)
- **Swipe Left** → Delete (marks for deletion)
- **Swipe Up** → Maybe (save to decide later pile)

### Smart Features
- **Undo Button** - Reverse your last decision anytime (Hinge-style wax seal button)
- **Tap to Zoom** - View photos fullscreen with pinch-to-zoom
- **Video Playback** - Play videos directly in the app
- **Auto-Save Progress** - Resume exactly where you left off
- **Smart Grouping** - Photos taken within 10 seconds are grouped together

### Filters
- All Photos
- Screenshots Only
- Last 30 Days
- By Year (2024, 2023, etc.)
- Largest Files First
- Maybe Pile

### Trash Review
- Review all marked photos before permanent deletion
- Restore individual photos
- See exactly what you're deleting
- Photos move to iOS "Recently Deleted" (30-day recovery)

### Stats & Celebration
- See how much space you freed
- Count of photos reviewed and deleted
- Satisfying completion screen

## Design

Tidy features a unique **old library / Renaissance** aesthetic:

- Warm, scholarly, quietly luxurious design
- Parchment-textured backgrounds
- Antique gold accents
- Wax seal-styled undo button
- Elegant serif typography (Newsreader/Georgia)
- Archival photo card styling with stacked depth effect
- Full dark mode support

## Technical Stack

- **Platform**: iOS 16+
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Photo Access**: PhotoKit (PHPhotoLibrary)
- **Architecture**: MVVM with Observable
- **Storage**: UserDefaults / @AppStorage (local only)

## Project Structure

```
Tidy/
├── TidyApp.swift                    # App entry point
├── ContentView.swift                # Root navigation
│
├── Theme/
│   └── TidyTheme.swift              # Design system (colors, typography, dimensions)
│
├── Models/
│   ├── PhotoItem.swift              # Photo/video wrapper
│   ├── PhotoGroup.swift             # Timestamp-based grouping
│   ├── SwipeDecision.swift          # Keep/Delete/Maybe enum
│   └── SessionStats.swift           # Statistics tracking
│
├── Services/
│   ├── PhotoLibraryService.swift    # PhotoKit integration
│   ├── PhotoCacheService.swift      # Image caching
│   └── PersistenceService.swift     # UserDefaults wrapper
│
├── ViewModels/
│   ├── MainSwipeViewModel.swift     # Core swipe logic
│   ├── TrashViewModel.swift         # Trash management
│   └── FilterViewModel.swift        # Filter state
│
├── Views/
│   ├── Onboarding/                  # Permission request
│   ├── MainSwipe/                   # Core swiping interface
│   │   ├── MainSwipeView.swift
│   │   ├── PhotoCardView.swift
│   │   ├── CardStackView.swift
│   │   ├── SwipeIndicatorsView.swift
│   │   ├── UndoButtonView.swift
│   │   └── ProgressBarView.swift
│   ├── PhotoDetail/                 # Fullscreen zoom + video
│   ├── Filters/                     # Filter selection
│   ├── Trash/                       # Deletion review
│   ├── Maybe/                       # Maybe pile
│   ├── Stats/                       # Completion celebration
│   └── Components/                  # Reusable components
│
└── Extensions/
    ├── Color+Hex.swift              # Hex color support
    └── PHAsset+Extensions.swift     # PhotoKit helpers
```

## Getting Started

### Requirements
- Xcode 15+
- iOS 16+
- Swift 5.9+

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/tidy-ios.git
   ```

2. Open Xcode and create a new iOS App project:
   - Product Name: `Tidy`
   - Interface: SwiftUI
   - Language: Swift

3. Copy all Swift files from the `Tidy/` folder into your Xcode project

4. Add required capabilities in Xcode:
   - Photo Library Usage Description in Info.plist:
     ```xml
     <key>NSPhotoLibraryUsageDescription</key>
     <string>Tidy needs access to your photo library to help you review and organize your photos.</string>
     ```

5. Build and run on a device (photo library access requires a real device)

## Usage

1. **Launch the app** and grant photo library access
2. **Start swiping** through your photos:
   - Right = Keep
   - Left = Delete
   - Up = Maybe (decide later)
3. **Tap the undo button** (wax seal) to reverse any decision
4. **Use filters** to focus on specific photo types or time periods
5. **Review trash** before confirming deletions
6. **Celebrate** with satisfying stats when you're done!

## Privacy Policy

Tidy is designed with privacy as the #1 priority:

- We collect **zero** data
- We make **zero** network requests
- Your photos **never** leave your device
- All processing happens **locally** on your iPhone
- Deleted photos go to iOS Recently Deleted, giving you 30 days to recover

## What's NOT Included

By design, Tidy does not include:
- Network/internet code
- Analytics or crash reporting
- Advertisements
- In-app purchases
- Account systems
- Social sharing
- Cloud backup
- "Pro" upsells

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Design inspired by vintage library and archival aesthetics
- Built with SwiftUI and PhotoKit
- Typography: Newsreader (Google Fonts) with Georgia fallback
