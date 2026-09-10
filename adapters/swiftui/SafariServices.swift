// Preview adapter for SafariServices. An in-app Safari view controller cannot
// exist headlessly: the controller is a plain UIViewController stand-in that
// holds its URL and configuration, presents nothing, and never calls its
// delegate. A screen that pushes one renders the screen; the link opens
// nowhere, which is the honest still-frame answer.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

open class SFSafariViewController: UIViewController {
    public struct Configuration {
        public var entersReaderIfAvailable: Bool = false
        public var barCollapsingEnabled: Bool = true
        public var activityButton: ActivityButton?
        public var eventAttribution: Any?
        public init() {}
    }

    open class ActivityButton: NSObject {
        public let templateImage: UIImage
        public let extensionIdentifier: String
        public init(templateImage: UIImage, extensionIdentifier: String) {
            self.templateImage = templateImage
            self.extensionIdentifier = extensionIdentifier
        }
    }

    public enum DismissButtonStyle: Int {
        case done, close, cancel
    }

    public let initialURL: URL
    public let configuration: Configuration
    open weak var delegate: (any SFSafariViewControllerDelegate)?
    open var preferredBarTintColor: UIColor?
    open var preferredControlTintColor: UIColor?
    open var dismissButtonStyle: DismissButtonStyle = .done

    public init(url URL: URL, configuration: Configuration) {
        initialURL = URL
        self.configuration = configuration
        super.init()
    }

    public convenience init(url URL: URL) {
        self.init(url: URL, configuration: Configuration())
    }

    public static func prewarmConnections(to URLs: [URL]) -> SFSafariViewControllerPrewarmingToken {
        SFSafariViewControllerPrewarmingToken()
    }
}

public final class SFSafariViewControllerPrewarmingToken: NSObject {
    public func invalidate() {}
}

public protocol SFSafariViewControllerDelegate: AnyObject {
    func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [Any]
    func safariViewController(_ controller: SFSafariViewController, excludedActivityTypesFor URL: URL, title: String?) -> [String]
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool)
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL)
    func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController)
}

extension SFSafariViewControllerDelegate {
    public func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [Any] { [] }
    public func safariViewController(_ controller: SFSafariViewController, excludedActivityTypesFor URL: URL, title: String?) -> [String] { [] }
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}
    public func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {}
    public func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {}
    public func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController) {}
}

/// Web authentication sessions have no browser to run in; the completion is
/// never called and `start()` reports that it could not begin.
open class SFAuthenticationSession: NSObject {
    public typealias CompletionHandler = (URL?, Error?) -> Void
    public init(url URL: URL, callbackURLScheme: String?, completionHandler: @escaping CompletionHandler) {}
    open func start() -> Bool { false }
    open func cancel() {}
}
