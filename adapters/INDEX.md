# Adapters catalogue

Drop-in preview adapters for packages that cannot run inside a preview. Copy
the file into the framework's mocks directory and the engine substitutes it for
the real package in preview builds only. How adapters work is taught by the
previewing-mobile-apps skill that `mobai-dev setup` installs from inside the
binary, and the engine's `PREVIEW_UNSUPPORTED_MODULE` diagnostic names the
exact file to write.

“Tested” means the adapter has a dedicated engine test. Other entries are
application-proven but still need a focused regression fixture.

| framework | package | file | covers | tested |
|---|---|---|---|---|
| React Native | react-native-image-picker | [rn/react-native-image-picker.ts](rn/react-native-image-picker.ts) | launchCamera, launchImageLibrary | yes |
| React Native | react-native-maps | [rn/react-native-maps.tsx](rn/react-native-maps.tsx) | MapView and Marker placeholders | no |
| Flutter | image_picker | [flutter/image_picker.dart](flutter/image_picker.dart) | pickImage and pickMedia | no |
| SwiftUI | AVFoundation | [swiftui/AVFoundation.swift](swiftui/AVFoundation.swift) | inert players and export sessions | no |
| SwiftUI | AVKit | [swiftui/AVKit.swift](swiftui/AVKit.swift) | VideoPlayer and CMTime surface | no |
| SwiftUI | AudioToolbox | [swiftui/AudioToolbox.swift](swiftui/AudioToolbox.swift) | silent system sounds | no |
| SwiftUI | AuthenticationServices | [swiftui/AuthenticationServices.swift](swiftui/AuthenticationServices.swift) | web-authentication environment session with typed failure | no |
| SwiftUI | BackgroundTasks | [swiftui/BackgroundTasks.swift](swiftui/BackgroundTasks.swift) | inert registration, requests, completion, and cancellation | no |
| SwiftUI | Bodega | [swiftui/Bodega.swift](swiftui/Bodega.swift) | empty storage reads and non-persistent writes | no |
| SwiftUI | ButtonKit | [swiftui/ButtonKit.swift](swiftui/ButtonKit.swift) | AsyncButton passthrough | no |
| SwiftUI | Charts | [swiftui/Charts.swift](swiftui/Charts.swift) | common marks, axes, selection, scales, and empty chart layout | no |
| SwiftUI | CodeScanner | [swiftui/CodeScanner.swift](swiftui/CodeScanner.swift) | scanner API and stable placeholder | no |
| SwiftUI | CoreHaptics | [swiftui/CoreHaptics.swift](swiftui/CoreHaptics.swift) | unavailable haptics hardware | no |
| SwiftUI | CryptoKit | [swiftui/CryptoKit.swift](swiftui/CryptoKit.swift) | right-shaped keys without cryptography | no |
| SwiftUI | EmojiText | [swiftui/EmojiText.swift](swiftui/EmojiText.swift) | local text without remote emoji loading | no |
| SwiftUI | Gifu | [swiftui/Gifu.swift](swiftui/Gifu.swift) | inert GIFImageView animation | no |
| SwiftUI | KeychainSwift | [swiftui/KeychainSwift.swift](swiftui/KeychainSwift.swift) | in-memory keychain for the preview session | no |
| SwiftUI | LinkPresentation | [swiftui/LinkPresentation.swift](swiftui/LinkPresentation.swift) | editable and empty fetched link metadata | no |
| SwiftUI | MapKit | [swiftui/MapKit.swift](swiftui/MapKit.swift) | map placeholder reading the mocked location | yes |
| SwiftUI | MarkdownUI | [swiftui/MarkdownUI.swift](swiftui/MarkdownUI.swift) | paragraphs, bold headings, and bullet rows | no |
| SwiftUI | MediaPlayer | [swiftui/MediaPlayer.swift](swiftui/MediaPlayer.swift) | in-memory Now Playing state and inert remote commands | no |
| SwiftUI | NaturalLanguage | [swiftui/NaturalLanguage.swift](swiftui/NaturalLanguage.swift) | empty recognition results | no |
| SwiftUI | Nuke | [swiftui/Nuke.swift](swiftui/Nuke.swift) | requests, image pipeline, cache, and processors | no |
| SwiftUI | NukeUI | [swiftui/NukeUI.swift](swiftui/NukeUI.swift) | LazyImage placeholder and remote-image channel | no |
| SwiftUI | Photos | [swiftui/Photos.swift](swiftui/Photos.swift) | denied authorization and empty fetches | no |
| SwiftUI | PhotosUI | [swiftui/PhotosUI.swift](swiftui/PhotosUI.swift) | PhotosPicker that loads nothing | no |
| SwiftUI | RevenueCat | [swiftui/RevenueCat.swift](swiftui/RevenueCat.swift) | empty products and entitlements, cancelled purchases | no |
| SwiftUI | SFSafeSymbols | [swiftui/SFSafeSymbols.swift](swiftui/SFSafeSymbols.swift) | RawRepresentable symbols and deterministic picker inventory | no |
| SwiftUI | Sentry | [swiftui/Sentry.swift](swiftui/Sentry.swift) | no-op crash reporting and tracing | no |
| SwiftUI | SwiftSoup | [swiftui/SwiftSoup.swift](swiftui/SwiftSoup.swift) | empty DOM walk and plain-text clean | no |
| SwiftUI | SwipeActions | [swiftui/SwipeActions.swift](swiftui/SwipeActions.swift) | closed-state swipe containers and action labels | no |
| SwiftUI | SwiftyCrop | [swiftui/SwiftyCrop.swift](swiftui/SwiftyCrop.swift) | uncropped image placeholder and configuration | no |
| SwiftUI | TelemetryDeck | [swiftui/TelemetryDeck.swift](swiftui/TelemetryDeck.swift) | typed configuration and no-op signals | no |
| SwiftUI | Translation | [swiftui/Translation.swift](swiftui/Translation.swift) | translation session surface with no translated content | no |
| SwiftUI | UniformTypeIdentifiers | [swiftui/UniformTypeIdentifiers.swift](swiftui/UniformTypeIdentifiers.swift) | common UTType identifiers | no |
| SwiftUI | UserNotifications | [swiftui/UserNotifications.swift](swiftui/UserNotifications.swift) | inert center, delegate, requests, and presentation options | no |
| SwiftUI | WishKit | [swiftui/WishKit.swift](swiftui/WishKit.swift) | configuration and FeedbackListView placeholder | no |
| SwiftUI | _Translation_SwiftUI | [swiftui/_Translation_SwiftUI.swift](swiftui/_Translation_SwiftUI.swift) | SwiftUI translation overlay declarations | no |

Mocks directories: `.mobai/preview/rn/mocks/`,
`.mobai/preview/flutter/mocks/`, `.mobai/preview/swiftui/mocks/`.

The [SwiftUI promotion record](swiftui/CANDIDATES.md) explains which reviewed
files were intentionally not published because their generated source was
empty, app-owned, or superseded by the engine's normalized Apple SDK catalogue.

Contributions welcome: one file per package, implement only the package-owned
surface real applications use, read the world through preview primitives when
available, and document what the adapter deliberately does not simulate.
