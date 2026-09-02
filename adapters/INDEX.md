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
| React Native | react-native-permissions | [rn/react-native-permissions.ts](rn/react-native-permissions.ts) | check, request, multiple, notifications on the permissions primitive | no |
| React Native | react-native-device-info | [rn/react-native-device-info.ts](rn/react-native-device-info.ts) | fixed iPhone device values | no |
| React Native | @react-native-clipboard/clipboard | [rn/@react-native-clipboard/clipboard.ts](rn/@react-native-clipboard/clipboard.ts) | get and set on the clipboard primitive, useClipboard | no |
| React Native | @notifee/react-native | [rn/@notifee/react-native.ts](rn/@notifee/react-native.ts) | permission through the primitive, no-op local notifications and badges | no |
| React Native | @sentry/react-native | [rn/@sentry/react-native.tsx](rn/@sentry/react-native.tsx) | no-op init, capture, scope, ErrorBoundary and wrap passthrough | no |
| React Native | @react-native-firebase/app | [rn/@react-native-firebase/app.ts](rn/@react-native-firebase/app.ts) | default app handle | no |
| React Native | @react-native-firebase/messaging | [rn/@react-native-firebase/messaging.ts](rn/@react-native-firebase/messaging.ts) | constant token, initial notification from the primitive, quiet listeners | no |
| React Native | react-native-keyboard-controller | [rn/react-native-keyboard-controller.tsx](rn/react-native-keyboard-controller.tsx) | providers and aware views as plain views, closed keyboard hooks | no |
| React Native | expo-image | [rn/expo-image.tsx](rn/expo-image.tsx) | Image and ImageBackground over react-native-web, contentFit, placeholder box | no |
| React Native | react-native-mmkv | [rn/react-native-mmkv.ts](rn/react-native-mmkv.ts) | in-memory MMKV with listeners and the useMMKV* hooks | no |
| React Native | react-native-svg | [rn/react-native-svg.tsx](rn/react-native-svg.tsx) | primitive elements as DOM svg, SvgXml | no |
| React Native | expo-font | [rn/expo-font.ts](rn/expo-font.ts) | the app's font map loaded for real through @font-face | no |
| React Native | expo-notifications | [rn/expo-notifications.ts](rn/expo-notifications.ts) | permissions, tokens, listeners and badges on the primitives | no |
| React Native | @expo/vector-icons | [rn/@expo/vector-icons.tsx](rn/@expo/vector-icons.tsx) | every single-font set from the real glyph maps and fonts (the folder `rn/@expo/vector-icons/` goes with it) | no |
| Flutter | google_maps_flutter | [flutter/google_maps_flutter.dart](flutter/google_maps_flutter.dart) | GoogleMap placeholder with camera and marker count, markers, BitmapDescriptor | no |
| Flutter | device_info_plus | [flutter/device_info_plus.dart](flutter/device_info_plus.dart) | fixed iOS, Android and macOS device values | no |
| Flutter | share_handler | [flutter/share_handler.dart](flutter/share_handler.dart) | data classes, no initial share, quiet stream | no |
| Flutter | home_widget | [flutter/home_widget.dart](flutter/home_widget.dart) | no-op widget updates | no |
| Flutter | flutter_displaymode | [flutter/flutter_displaymode.dart](flutter/flutter_displaymode.dart) | no-op refresh rate | no |
| Flutter | flutter_native_splash | [flutter/flutter_native_splash.dart](flutter/flutter_native_splash.dart) | no-op preserve and remove | no |
| Flutter | pointer_interceptor | [flutter/pointer_interceptor.dart](flutter/pointer_interceptor.dart) | transparent wrapper | no |
| Flutter | permission_handler | [flutter/permission_handler.dart](flutter/permission_handler.dart) | every permission granted | no |
| Flutter | youtube_player_iframe | [flutter/youtube_player_iframe.dart](flutter/youtube_player_iframe.dart) | controller API with a placeholder player | no |
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
