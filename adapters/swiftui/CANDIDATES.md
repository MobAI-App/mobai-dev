# SwiftUI adapter promotion record

This file records the generated mocks reviewed while building the public
catalogue. A mock is published only when its declarations belong to the module
named by the file and its preview behaviour is explicit. Application-owned
declarations must never be copied into a framework adapter.

## Published after cleanup

The Swift files beside this document are the promoted adapters. The newly
promoted set is:

- Apple/platform: AuthenticationServices, BackgroundTasks, Charts,
  LinkPresentation, and MediaPlayer.
- Third-party: CodeScanner, MarkdownUI, SFSafeSymbols, SwiftyCrop, and
  SwipeActions.

The previously promoted adapters were also audited. Unfinished compiler notes
were removed from Bodega, Gifu, KeychainSwift, and RevenueCat; RevenueCat was
replaced with a typed empty-store implementation; application names were
removed from reusable comments.

## Supplied by the engine SDK catalogue

These Apple modules have normalized SDK IR in the SwiftUI engine and should be
materialized from that catalogue at runtime instead of being copied from an
application's generated mocks:

- AppIntents
- CoreBluetooth
- FoundationModels
- ImageIO
- Intents
- MobileCoreServices
- QuickLook
- Security
- Social
- StoreKit

HealthKit, OpenGLES, and TVServices need either normalized declarations or a
real application-proven surface before promotion. The generated files reviewed
for them were empty, placeholders, or contained application-owned types.

## Deferred third-party modules

- Libmpv: its C surface is too large for the generated placeholder and the
  reviewed file mixed module constants with application logging types.
- Negentropy: the reviewed file contained application-owned declarations and
  did not describe the package API sufficiently.
- NostrSDK: the reviewed file contained test/XCTest declarations and an
  incomplete package surface.

These names remain candidates, not published adapters. Promotion requires a
clean module-source extraction or a small hand-written adapter verified against
an application without adding engine-specific code to that application.
