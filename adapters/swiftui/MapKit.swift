// MobAI curated stand-in: MapKit
// Managed by the engine while unchanged; edit it and it is yours.
//
// Apple's MapKit for the preview: the SwiftUI Map, both the iOS 14 API
// (`Map(coordinateRegion:annotationItems:annotationContent:)` with MapMarker,
// MapPin and MapAnnotation) and the iOS 17 one (`Map(position:) { Marker;
// Annotation; UserAnnotation }`), the camera and region types, and the
// coordinate types apps reach through `import MapKit`. The map draws as a
// flat land-coloured ground with a faint grid, projected equirectangularly
// inside its region; markers are pins with their titles as real text,
// annotations are the app's own views at their projected points, and the
// user location is a blue dot where the scenario's `location` puts it.
// Interaction (pan, zoom, selection), tiles, search, directions and
// MKMapView are not covered; the camera modifiers compile and do nothing.

import Foundation
import SwiftUI
import MobAIPreview

// The coordinate types are CoreLocation's, supplied by the engine's
// CoreLocation supplement, and re-exported here the way the real MapKit
// re-exports CoreLocation.
@_exported import CoreLocation

// MARK: - Regions, spans, cameras

public struct MKCoordinateSpan: Hashable, Sendable {
    public var latitudeDelta: CLLocationDegrees
    public var longitudeDelta: CLLocationDegrees
    public init() {
        latitudeDelta = 0
        longitudeDelta = 0
    }
    public init(latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public func MKCoordinateSpanMake(_ latitudeDelta: CLLocationDegrees, _ longitudeDelta: CLLocationDegrees) -> MKCoordinateSpan {
    MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
}

public struct MKCoordinateRegion: Hashable, Sendable {
    public var center: CLLocationCoordinate2D
    public var span: MKCoordinateSpan
    public init() {
        center = CLLocationCoordinate2D()
        span = MKCoordinateSpan()
    }
    public init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.center = center
        self.span = span
    }
    public init(center: CLLocationCoordinate2D, latitudinalMeters: CLLocationDistance, longitudinalMeters: CLLocationDistance) {
        self.center = center
        let latDelta = latitudinalMeters / 111_320
        let lonDelta = longitudinalMeters / max(111_320 * cos(center.latitude * .pi / 180), 1)
        self.span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    }
}

public func MKCoordinateRegionMake(_ center: CLLocationCoordinate2D, _ span: MKCoordinateSpan) -> MKCoordinateRegion {
    MKCoordinateRegion(center: center, span: span)
}

public func MKCoordinateRegionMakeWithDistance(_ center: CLLocationCoordinate2D, _ latitudinalMeters: CLLocationDistance, _ longitudinalMeters: CLLocationDistance) -> MKCoordinateRegion {
    MKCoordinateRegion(center: center, latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
}

public struct MKMapPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init() {
        x = 0
        y = 0
    }
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    public init(_ coordinate: CLLocationCoordinate2D) {
        x = (coordinate.longitude + 180) / 360
        y = (90 - coordinate.latitude) / 180
    }
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 90 - y * 180, longitude: x * 360 - 180)
    }
}

public struct MKMapSize: Hashable, Sendable {
    public var width: Double
    public var height: Double
    public init() {
        width = 0
        height = 0
    }
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct MKMapRect: Hashable, Sendable {
    public var origin: MKMapPoint
    public var size: MKMapSize
    public init() {
        origin = MKMapPoint()
        size = MKMapSize()
    }
    public init(origin: MKMapPoint, size: MKMapSize) {
        self.origin = origin
        self.size = size
    }
    public init(x: Double, y: Double, width: Double, height: Double) {
        origin = MKMapPoint(x: x, y: y)
        size = MKMapSize(width: width, height: height)
    }
    public static let world = MKMapRect(x: 0, y: 0, width: 1, height: 1)
    public static let null = MKMapRect(x: .infinity, y: .infinity, width: 0, height: 0)
    public var isNull: Bool { origin.x.isInfinite }
}

public struct MapCamera: Hashable, Sendable {
    public var centerCoordinate: CLLocationCoordinate2D
    public var distance: Double
    public var heading: Double
    public var pitch: Double
    public init(centerCoordinate: CLLocationCoordinate2D, distance: Double, heading: Double = 0, pitch: Double = 0) {
        self.centerCoordinate = centerCoordinate
        self.distance = distance
        self.heading = heading
        self.pitch = pitch
    }
}

/// Where the map looks. Only `.region` and `.camera` carry a place; the rest
/// resolve at layout time (all annotations, the mocked location, or a default).
public struct MapCameraPosition: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case automatic
        case region(MKCoordinateRegion)
        case camera(MapCamera)
        case rect(MKMapRect)
        case userLocation(fallback: MKCoordinateRegion?)
        case item
    }
    let kind: Kind

    public static let automatic = MapCameraPosition(kind: .automatic)
    public static func region(_ region: MKCoordinateRegion) -> MapCameraPosition { MapCameraPosition(kind: .region(region)) }
    public static func camera(_ camera: MapCamera) -> MapCameraPosition { MapCameraPosition(kind: .camera(camera)) }
    public static func rect(_ rect: MKMapRect) -> MapCameraPosition { MapCameraPosition(kind: .rect(rect)) }
    public static func userLocation(followsHeading: Bool = false, fallback: MapCameraPosition) -> MapCameraPosition {
        if case let .region(region) = fallback.kind { return MapCameraPosition(kind: .userLocation(fallback: region)) }
        return MapCameraPosition(kind: .userLocation(fallback: nil))
    }
    public static func item(_ item: MKMapItem, allowsAutomaticPitch: Bool = true) -> MapCameraPosition { MapCameraPosition(kind: .item) }

    public var region: MKCoordinateRegion? {
        if case let .region(r) = kind { return r }
        return nil
    }
    public var camera: MapCamera? {
        if case let .camera(c) = kind { return c }
        return nil
    }
    public var positionedByUser: Bool { false }
    public var followsUserLocation: Bool {
        if case .userLocation = kind { return true }
        return false
    }
}

public struct MapCameraBounds: Sendable {
    public init(centerCoordinateBounds: MKCoordinateRegion? = nil, minimumDistance: Double? = nil, maximumDistance: Double? = nil) {}
    public init(centerCoordinateBounds: MKMapRect, minimumDistance: Double? = nil, maximumDistance: Double? = nil) {}
    public init(minimumDistance: Double? = nil, maximumDistance: Double? = nil) {}
}

public struct MapCameraUpdateContext: Sendable {
    public var camera: MapCamera
    public var region: MKCoordinateRegion
    public var rect: MKMapRect
}

public struct MapCameraUpdateFrequency: Hashable, Sendable {
    public init() {}
    public static let continuous = MapCameraUpdateFrequency()
    public static let onEnd = MapCameraUpdateFrequency()
}

public struct MapInteractionModes: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let pan = MapInteractionModes(rawValue: 1)
    public static let zoom = MapInteractionModes(rawValue: 2)
    public static let pitch = MapInteractionModes(rawValue: 4)
    public static let rotate = MapInteractionModes(rawValue: 8)
    public static let all: MapInteractionModes = [.pan, .zoom, .pitch, .rotate]
}

public struct MapStyle: Sendable {
    public init() {}
    public static let standard = MapStyle()
    public static let imagery = MapStyle()
    public static let hybrid = MapStyle()
    public static func standard(elevation: MapStyle.Elevation = .automatic, emphasis: MapStyle.StandardEmphasis = .automatic, pointsOfInterest: PointOfInterestCategories = .all, showsTraffic: Bool = false) -> MapStyle { MapStyle() }
    public static func imagery(elevation: MapStyle.Elevation = .automatic) -> MapStyle { MapStyle() }
    public static func hybrid(elevation: MapStyle.Elevation = .automatic, pointsOfInterest: PointOfInterestCategories = .all, showsTraffic: Bool = false) -> MapStyle { MapStyle() }
    public struct Elevation: Sendable {
        public init() {}
        public static let automatic = Elevation()
        public static let flat = Elevation()
        public static let realistic = Elevation()
    }
    public struct StandardEmphasis: Sendable {
        public init() {}
        public static let automatic = StandardEmphasis()
        public static let muted = StandardEmphasis()
    }
}

public struct PointOfInterestCategories: Sendable {
    public init() {}
    public static let all = PointOfInterestCategories()
    public static let excludingAll = PointOfInterestCategories()
    public static func including(_ categories: [MKPointOfInterestCategory]) -> PointOfInterestCategories { PointOfInterestCategories() }
    public static func excluding(_ categories: [MKPointOfInterestCategory]) -> PointOfInterestCategories { PointOfInterestCategories() }
}

public struct MKPointOfInterestCategory: Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let airport = MKPointOfInterestCategory(rawValue: "airport")
    public static let cafe = MKPointOfInterestCategory(rawValue: "cafe")
    public static let restaurant = MKPointOfInterestCategory(rawValue: "restaurant")
    public static let hotel = MKPointOfInterestCategory(rawValue: "hotel")
    public static let park = MKPointOfInterestCategory(rawValue: "park")
    public static let store = MKPointOfInterestCategory(rawValue: "store")
}

public struct MKUserTrackingMode: Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let none = MKUserTrackingMode(rawValue: 0)
    public static let follow = MKUserTrackingMode(rawValue: 1)
    public static let followWithHeading = MKUserTrackingMode(rawValue: 2)
}

public struct MapUserTrackingMode: Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let none = MapUserTrackingMode(rawValue: 0)
    public static let follow = MapUserTrackingMode(rawValue: 1)
}

/// A place, as MKMapItem is used from SwiftUI: a coordinate and a name.
public final class MKMapItem: @unchecked Sendable {
    public var name: String?
    public var placemark: MKPlacemark
    public var isCurrentLocation: Bool { false }
    public var coordinate: CLLocationCoordinate2D { placemark.coordinate }
    public init(placemark: MKPlacemark) {
        self.placemark = placemark
    }
    public init() {
        self.placemark = MKPlacemark(coordinate: CLLocationCoordinate2D())
    }
    public static func forCurrentLocation() -> MKMapItem {
        let fix = location.current()
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: fix?.lat ?? 0, longitude: fix?.lng ?? 0)))
        item.name = fix?.label
        return item
    }
    public func openInMaps(launchOptions: [String: Any]? = nil) {}
}

public final class MKPlacemark: @unchecked Sendable {
    public let coordinate: CLLocationCoordinate2D
    public var title: String?
    public var name: String? { title }
    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    public init(coordinate: CLLocationCoordinate2D, addressDictionary: [String: Any]?) {
        self.coordinate = coordinate
    }
}

// MARK: - Content

/// What a map draws: everything reduces to a list of these.
public struct PreviewMapItem {
    public enum Kind { case marker, pin, view, userLocation, polyline, circle }
    public var kind: Kind
    public var coordinate: CLLocationCoordinate2D
    public var title: String?
    public var tint: Color?
    public var view: AnyView?
    public var anchor: UnitPoint = .center
    public var points: [CLLocationCoordinate2D] = []
    public var radius: CLLocationDistance = 0
}

public protocol MapContent {
    var previewMapItems: [PreviewMapItem] { get }
}

public struct MapItemGroup: MapContent {
    public var previewMapItems: [PreviewMapItem]
    public init(_ items: [PreviewMapItem]) { previewMapItems = items }
}

extension Never: MapContent {
    public var previewMapItems: [PreviewMapItem] { [] }
}

extension Optional: MapContent where Wrapped: MapContent {
    public var previewMapItems: [PreviewMapItem] { self?.previewMapItems ?? [] }
}

extension ForEach: MapContent where Content: MapContent {
    public var previewMapItems: [PreviewMapItem] {
        data.flatMap { content($0).previewMapItems }
    }
    public init(_ data: Data, @MapContentBuilder content: @escaping (Data.Element) -> Content) where ID == Data.Element.ID, Data.Element: Identifiable {
        self.init(_previewData: data, content: content)
    }
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @MapContentBuilder content: @escaping (Data.Element) -> Content) {
        self.init(_previewData: data, id: id, content: content)
    }
}

@resultBuilder
public enum MapContentBuilder {
    public static func buildExpression<C: MapContent>(_ content: C) -> MapItemGroup { MapItemGroup(content.previewMapItems) }
    public static func buildBlock(_ parts: MapItemGroup...) -> MapItemGroup { MapItemGroup(parts.flatMap(\.previewMapItems)) }
    public static func buildOptional(_ part: MapItemGroup?) -> MapItemGroup { part ?? MapItemGroup([]) }
    public static func buildEither(first: MapItemGroup) -> MapItemGroup { first }
    public static func buildEither(second: MapItemGroup) -> MapItemGroup { second }
    public static func buildArray(_ parts: [MapItemGroup]) -> MapItemGroup { MapItemGroup(parts.flatMap(\.previewMapItems)) }
    public static func buildLimitedAvailability(_ part: MapItemGroup) -> MapItemGroup { part }
}

public struct Marker<Label: View>: MapContent {
    public var previewMapItems: [PreviewMapItem]
    public init(_ title: LocalizedStringKey, coordinate: CLLocationCoordinate2D) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: "\(title)")]
    }
    public init<S: StringProtocol>(_ title: S, coordinate: CLLocationCoordinate2D) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: String(title))]
    }
    public init(_ title: LocalizedStringKey, systemImage: String, coordinate: CLLocationCoordinate2D) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: "\(title)")]
    }
    public init<S: StringProtocol>(_ title: S, systemImage: String, coordinate: CLLocationCoordinate2D) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: String(title))]
    }
    public init(_ title: LocalizedStringKey, monogram: Text, coordinate: CLLocationCoordinate2D) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: "\(title)")]
    }
    public init(_ title: LocalizedStringKey, image: String, coordinate: CLLocationCoordinate2D) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: "\(title)")]
    }
    public init(coordinate: CLLocationCoordinate2D, @ViewBuilder label: () -> Label) {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: coordinate, title: PreviewMap.plainText(of: label()))]
    }
    public init(item: MKMapItem) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .marker, coordinate: item.coordinate, title: item.name)]
    }
}

public struct Annotation<Label: View, Content: View>: MapContent {
    public var previewMapItems: [PreviewMapItem]
    public init(_ title: LocalizedStringKey, coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, @ViewBuilder content: () -> Content) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .view, coordinate: coordinate, title: "\(title)", view: AnyView(content()), anchor: anchor)]
    }
    public init<S: StringProtocol>(_ title: S, coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, @ViewBuilder content: () -> Content) where Label == Text {
        previewMapItems = [PreviewMapItem(kind: .view, coordinate: coordinate, title: String(title), view: AnyView(content()), anchor: anchor)]
    }
    public init(coordinate: CLLocationCoordinate2D, anchor: UnitPoint = .center, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        previewMapItems = [PreviewMapItem(kind: .view, coordinate: coordinate, title: PreviewMap.plainText(of: label()), view: AnyView(content()), anchor: anchor)]
    }
}

public struct UserAnnotation: MapContent {
    public var previewMapItems: [PreviewMapItem] {
        guard let fix = location.current() else { return [] }
        return [PreviewMapItem(kind: .userLocation, coordinate: CLLocationCoordinate2D(latitude: fix.lat, longitude: fix.lng))]
    }
    public init() {}
    public init<C: View>(anchor: UnitPoint = .center, @ViewBuilder content: (UserLocation) -> C) {}
}

public struct UserLocation: Sendable {
    public var location: CLLocationCoordinate2D?
    public var heading: Double?
}

public struct MapPolyline: MapContent {
    public var previewMapItems: [PreviewMapItem]
    public init(coordinates: [CLLocationCoordinate2D], contourStyle: ContourStyle = .straight) {
        previewMapItems = [PreviewMapItem(kind: .polyline, coordinate: coordinates.first ?? CLLocationCoordinate2D(), points: coordinates)]
    }
    public init(points: [MKMapPoint], contourStyle: ContourStyle = .straight) {
        let coordinates = points.map(\.coordinate)
        previewMapItems = [PreviewMapItem(kind: .polyline, coordinate: coordinates.first ?? CLLocationCoordinate2D(), points: coordinates)]
    }
    public struct ContourStyle: Sendable {
        public init() {}
        public static let straight = ContourStyle()
        public static let geodesic = ContourStyle()
    }
}

public struct MapCircle: MapContent {
    public var previewMapItems: [PreviewMapItem]
    public init(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        previewMapItems = [PreviewMapItem(kind: .circle, coordinate: center, radius: radius)]
    }
}

public struct MapPolygon: MapContent {
    public var previewMapItems: [PreviewMapItem]
    public init(coordinates: [CLLocationCoordinate2D]) {
        var points = coordinates
        if let first = coordinates.first { points.append(first) }
        previewMapItems = [PreviewMapItem(kind: .polyline, coordinate: coordinates.first ?? CLLocationCoordinate2D(), points: points)]
    }
}

/// Content modifiers: colour travels, the rest compiles.
extension MapContent {
    public func tint<S: ShapeStyle>(_ style: S) -> MapItemGroup {
        MapItemGroup(previewMapItems.map { item in
            var i = item
            if let color = style as? Color { i.tint = color }
            return i
        })
    }
    public func foregroundStyle<S: ShapeStyle>(_ style: S) -> MapItemGroup { tint(style) }
    public func stroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> MapItemGroup { tint(style) }
    public func stroke<S: ShapeStyle>(_ style: S, style strokeStyle: StrokeStyle) -> MapItemGroup { tint(style) }
    public func strokeStyle(style: StrokeStyle) -> MapItemGroup { MapItemGroup(previewMapItems) }
    public func annotationTitles(_ visibility: Visibility) -> MapItemGroup { MapItemGroup(previewMapItems) }
    public func annotationSubtitles(_ visibility: Visibility) -> MapItemGroup { MapItemGroup(previewMapItems) }
    public func tag<V: Hashable>(_ tag: V) -> MapItemGroup { MapItemGroup(previewMapItems) }
    public func mapOverlayLevel(level: MKOverlayLevel) -> MapItemGroup { MapItemGroup(previewMapItems) }
}

public struct MKOverlayLevel: Hashable, Sendable {
    public init() {}
    public static let aboveRoads = MKOverlayLevel()
    public static let aboveLabels = MKOverlayLevel()
}

// MARK: - The iOS 14 annotation protocol

public protocol MapAnnotationProtocol {
    var previewMapItem: PreviewMapItem { get }
}

public struct MapMarker: MapAnnotationProtocol {
    public var previewMapItem: PreviewMapItem
    public init(coordinate: CLLocationCoordinate2D, tint: Color? = nil) {
        previewMapItem = PreviewMapItem(kind: .marker, coordinate: coordinate, tint: tint)
    }
}

public struct MapPin: MapAnnotationProtocol {
    public var previewMapItem: PreviewMapItem
    public init(coordinate: CLLocationCoordinate2D, tint: Color? = nil) {
        previewMapItem = PreviewMapItem(kind: .pin, coordinate: coordinate, tint: tint)
    }
}

public struct MapAnnotation<Content: View>: MapAnnotationProtocol {
    public var previewMapItem: PreviewMapItem
    public init(coordinate: CLLocationCoordinate2D, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5), @ViewBuilder content: () -> Content) {
        previewMapItem = PreviewMapItem(kind: .view, coordinate: coordinate, view: AnyView(content()), anchor: UnitPoint(x: anchorPoint.x, y: anchorPoint.y))
    }
}

// MARK: - The map

public struct Map<Content: MapContent>: View {
    private var items: [PreviewMapItem]
    private var region: MKCoordinateRegion?
    private var showsUser: Bool
    private var placeholderRegion: MKCoordinateRegion?

    @Environment(\.colorScheme) private var colorScheme

    // iOS 17
    public init(@MapContentBuilder content: () -> Content) {
        items = content().previewMapItems
        region = nil
        showsUser = false
    }
    public init(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> Content) {
        items = content().previewMapItems
        region = PreviewMap.region(of: position.wrappedValue)
        showsUser = position.wrappedValue.followsUserLocation
    }
    public init(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil) where Content == Never {
        items = []
        region = PreviewMap.region(of: position.wrappedValue)
        showsUser = position.wrappedValue.followsUserLocation
    }
    public init(initialPosition: MapCameraPosition = .automatic, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> Content) {
        items = content().previewMapItems
        region = PreviewMap.region(of: initialPosition)
        showsUser = initialPosition.followsUserLocation
    }
    public init(initialPosition: MapCameraPosition = .automatic, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, scope: Namespace.ID? = nil) where Content == Never {
        items = []
        region = PreviewMap.region(of: initialPosition)
        showsUser = initialPosition.followsUserLocation
    }
    public init<V: Hashable>(position: Binding<MapCameraPosition>, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<V?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> Content) {
        items = content().previewMapItems
        region = PreviewMap.region(of: position.wrappedValue)
        showsUser = position.wrappedValue.followsUserLocation
    }
    public init<V: Hashable>(initialPosition: MapCameraPosition = .automatic, bounds: MapCameraBounds? = nil, interactionModes: MapInteractionModes = .all, selection: Binding<V?>, scope: Namespace.ID? = nil, @MapContentBuilder content: () -> Content) {
        items = content().previewMapItems
        region = PreviewMap.region(of: initialPosition)
        showsUser = initialPosition.followsUserLocation
    }

    // iOS 14
    public init(coordinateRegion: Binding<MKCoordinateRegion>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil) where Content == Never {
        items = []
        region = coordinateRegion.wrappedValue
        showsUser = showsUserLocation
    }
    public init<Items: RandomAccessCollection, A: MapAnnotationProtocol>(coordinateRegion: Binding<MKCoordinateRegion>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil, annotationItems: Items, annotationContent: (Items.Element) -> A) where Content == Never, Items.Element: Identifiable {
        items = annotationItems.map { annotationContent($0).previewMapItem }
        region = coordinateRegion.wrappedValue
        showsUser = showsUserLocation
    }
    public init(mapRect: Binding<MKMapRect>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil) where Content == Never {
        items = []
        region = PreviewMap.region(of: mapRect.wrappedValue)
        showsUser = showsUserLocation
    }
    public init<Items: RandomAccessCollection, A: MapAnnotationProtocol>(mapRect: Binding<MKMapRect>, interactionModes: MapInteractionModes = .all, showsUserLocation: Bool = false, userTrackingMode: Binding<MapUserTrackingMode>? = nil, annotationItems: Items, annotationContent: (Items.Element) -> A) where Content == Never, Items.Element: Identifiable {
        items = annotationItems.map { annotationContent($0).previewMapItem }
        region = PreviewMap.region(of: mapRect.wrappedValue)
        showsUser = showsUserLocation
    }

    public var body: some View {
        GeometryReader { proxy in
            let layout = PreviewMap.layout(items: items, region: region, showsUser: showsUser, size: proxy.size, scheme: colorScheme)
            ZStack(alignment: .topLeading) {
                PreviewVector(svg: layout.svg)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                ForEach(Array(layout.labels.enumerated()), id: \.offset) { item in
                    Text(item.element.text)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .position(x: item.element.x, y: item.element.y)
                }
                ForEach(Array(layout.views.enumerated()), id: \.offset) { item in
                    item.element.view
                        .position(x: item.element.x, y: item.element.y)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .previewSemanticNode(type: "Map", label: "Map")
    }

    // Camera and style modifiers, declared on Map so a chain stays a Map.
    public func mapStyle(_ style: MapStyle) -> Map { self }
    public func mapControls<C: View>(@ViewBuilder _ content: () -> C) -> Map { self }
    public func mapControlVisibility(_ visibility: Visibility) -> Map { self }
    public func mapScope(_ scope: Namespace.ID) -> Map { self }
    public func onMapCameraChange(frequency: MapCameraUpdateFrequency = .onEnd, _ action: @escaping (MapCameraUpdateContext) -> Void) -> Map { self }
    public func onMapCameraChange(frequency: MapCameraUpdateFrequency = .onEnd, _ action: @escaping () -> Void) -> Map { self }
    public func mapFeatureSelectionDisabled(_ disabled: Bool) -> Map { self }
    public func mapFeatureSelectionAccessory(_ accessory: Any?) -> Map { self }
    public func mapItemDetailSelectionAccessory(_ accessory: Any?) -> Map { self }
}

/// The same modifiers on any view, for a chain that has left the Map type.
extension View {
    public func mapStyle(_ style: MapStyle) -> some View { self }
    public func mapControls<C: View>(@ViewBuilder _ content: () -> C) -> some View { self }
    public func mapControlVisibility(_ visibility: Visibility) -> some View { self }
    public func mapScope(_ scope: Namespace.ID) -> some View { self }
    public func onMapCameraChange(frequency: MapCameraUpdateFrequency = .onEnd, _ action: @escaping (MapCameraUpdateContext) -> Void) -> some View { self }
    public func onMapCameraChange(frequency: MapCameraUpdateFrequency = .onEnd, _ action: @escaping () -> Void) -> some View { self }
    public func mapFeatureSelectionDisabled(_ disabled: Bool) -> some View { self }
}

/// The controls apps put in `mapControls`; a preview draws none.
public struct MapCompass: View {
    public init(scope: Namespace.ID? = nil) {}
    public var body: some View { EmptyView() }
}
public struct MapPitchToggle: View {
    public init(scope: Namespace.ID? = nil) {}
    public var body: some View { EmptyView() }
}
public struct MapScaleView: View {
    public init(scope: Namespace.ID? = nil) {}
    public var body: some View { EmptyView() }
}
public struct MapUserLocationButton: View {
    public init(scope: Namespace.ID? = nil) {}
    public var body: some View { EmptyView() }
}
public struct MapZoomStepper: View {
    public init(scope: Namespace.ID? = nil) {}
    public var body: some View { EmptyView() }
}

// MARK: - Layout and drawing

public enum PreviewMap {
    struct Label {
        var text: String
        var x: Double
        var y: Double
    }
    struct Placed {
        var view: AnyView
        var x: Double
        var y: Double
    }
    struct Layout {
        var svg: String
        var labels: [Label]
        var views: [Placed]
    }

    static func region(of position: MapCameraPosition) -> MKCoordinateRegion? {
        switch position.kind {
        case let .region(r): return r
        case let .camera(c):
            let delta = max(c.distance / 111_320, 0.002)
            return MKCoordinateRegion(center: c.centerCoordinate, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
        case let .rect(rect): return region(of: rect)
        case let .userLocation(fallback):
            if let fix = location.current() {
                return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: fix.lat, longitude: fix.lng), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            }
            return fallback
        case .automatic, .item: return nil
        }
    }

    static func region(of rect: MKMapRect) -> MKCoordinateRegion? {
        guard !rect.isNull, rect.size.width > 0, rect.size.height > 0 else { return nil }
        let a = rect.origin.coordinate
        let b = MKMapPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height).coordinate
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (a.latitude + b.latitude) / 2, longitude: (a.longitude + b.longitude) / 2),
            span: MKCoordinateSpan(latitudeDelta: abs(a.latitude - b.latitude), longitudeDelta: abs(a.longitude - b.longitude)))
    }

    /// The region a map shows when the app left it automatic: every item
    /// with a fifth of padding, the scenario's location, or a default.
    static func resolvedRegion(items: [PreviewMapItem], region: MKCoordinateRegion?, showsUser: Bool, aspect: Double) -> MKCoordinateRegion {
        if let region, region.span.latitudeDelta > 0 || region.span.longitudeDelta > 0 {
            return region
        }
        var coordinates = items.flatMap { $0.kind == .polyline ? $0.points : [$0.coordinate] }
        if showsUser, let fix = location.current() {
            coordinates.append(CLLocationCoordinate2D(latitude: fix.lat, longitude: fix.lng))
        }
        if coordinates.isEmpty, let fix = location.current() {
            coordinates.append(CLLocationCoordinate2D(latitude: fix.lat, longitude: fix.lng))
        }
        guard let first = coordinates.first else {
            // Cupertino, the platform's own default when it knows nothing.
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        var minLat = first.latitude, maxLat = first.latitude, minLon = first.longitude, maxLon = first.longitude
        for c in coordinates {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        var latDelta = max((maxLat - minLat) * 1.4, 0.02)
        var lonDelta = max((maxLon - minLon) * 1.4, 0.02)
        // Keep the projection square-ish for the frame it lands in.
        if lonDelta / max(latDelta, 1e-9) < aspect { lonDelta = latDelta * aspect } else { latDelta = lonDelta / max(aspect, 1e-9) }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2), span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }

    static func layout(items: [PreviewMapItem], region: MKCoordinateRegion?, showsUser: Bool, size: CGSize, scheme: ColorScheme) -> Layout {
        let width = max(Double(size.width), 1), height = max(Double(size.height), 1)
        let region = resolvedRegion(items: items, region: region, showsUser: showsUser, aspect: width / height)
        let latSpan = max(region.span.latitudeDelta, 1e-9), lonSpan = max(region.span.longitudeDelta, 1e-9)
        func project(_ c: CLLocationCoordinate2D) -> (Double, Double) {
            let x = (c.longitude - (region.center.longitude - lonSpan / 2)) / lonSpan * width
            let y = ((region.center.latitude + latSpan / 2) - c.latitude) / latSpan * height
            return (x, y)
        }
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let dark = scheme == .dark
        let ground = dark ? "#2c2c2e" : "#e9e4d9"
        let grid = dark ? "#3a3a3c" : "#dcd6c8"
        let water = dark ? "#1c2a3a" : "#c5dbea"
        var paths: [String] = []
        paths.append("<path d=\"M 0 0 L \(t(width)) 0 L \(t(width)) \(t(height)) L 0 \(t(height)) Z\" fill=\"\(ground)\"/>")
        // A faint street grid every 48pt, and a water band along one edge so
        // the map reads as a map and not as a grey box.
        var g = ""
        var x = 24.0
        while x < width { g += String(format: " M %.1f 0 L %.1f %.1f", x, x, height); x += 48 }
        var y = 24.0
        while y < height { g += String(format: " M 0 %.1f L %.1f %.1f", y, width, y); y += 48 }
        paths.append("<path d=\"\(g.trimmingCharacters(in: .whitespaces))\" fill=\"none\" stroke=\"\(grid)\" stroke-width=\"1\"/>")
        paths.append(String(format: "<path d=\"M 0 %.1f C %.1f %.1f %.1f %.1f %.1f %.1f L %.1f %.1f L 0 %.1f Z\" fill=\"%@\"/>",
                            height * 0.82, width * 0.3, height * 0.7, width * 0.6, height * 0.95, width, height * 0.86, width, height, height, water))
        var labels: [Label] = []
        var views: [Placed] = []
        for item in items where item.kind == .polyline {
            guard item.points.count > 1 else { continue }
            var d = ""
            for (i, c) in item.points.enumerated() {
                let (px, py) = project(c)
                d += String(format: i == 0 ? "M %.1f %.1f" : " L %.1f %.1f", px, py)
            }
            paths.append("<path d=\"\(d)\" fill=\"none\" stroke=\"\(hex(item.tint ?? .blue, environment))\" stroke-width=\"3\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>")
        }
        for item in items where item.kind == .circle {
            let (cx, cy) = project(item.coordinate)
            let r = max(item.radius / (latSpan * 111_320) * height, 4)
            paths.append(String(format: "<path d=\"M %.1f %.1f A %.1f %.1f 0 1 0 %.1f %.1f A %.1f %.1f 0 1 0 %.1f %.1f Z\" fill=\"%@\" opacity=\"0.25\"/>", cx - r, cy, r, r, cx + r, cy, r, r, cx - r, cy, hex(item.tint ?? .blue, environment)))
        }
        for item in items where item.kind == .marker || item.kind == .pin {
            let (px, py) = project(item.coordinate)
            let color = hex(item.tint ?? .red, environment)
            // A pin: a teardrop with its point on the coordinate.
            paths.append(String(format: "<path d=\"M %.1f %.1f C %.1f %.1f %.1f %.1f %.1f %.1f C %.1f %.1f %.1f %.1f %.1f %.1f Z\" fill=\"%@\"/>",
                                px, py, px - 14, py - 14, px - 11, py - 30, px, py - 30, px + 11, py - 30, px + 14, py - 14, px, py, color))
            paths.append(String(format: "<path d=\"M %.1f %.1f A 4 4 0 1 0 %.1f %.1f A 4 4 0 1 0 %.1f %.1f Z\" fill=\"#ffffff\"/>", px - 4, py - 19, px + 4, py - 19, px - 4, py - 19))
            if let title = item.title, !title.isEmpty {
                labels.append(Label(text: title, x: px, y: py + 10))
            }
        }
        var userItems = items.filter { $0.kind == .userLocation }
        if showsUser, userItems.isEmpty, let fix = location.current() {
            userItems.append(PreviewMapItem(kind: .userLocation, coordinate: CLLocationCoordinate2D(latitude: fix.lat, longitude: fix.lng)))
        }
        for item in userItems {
            let (px, py) = project(item.coordinate)
            paths.append(String(format: "<path d=\"M %.1f %.1f A 12 12 0 1 0 %.1f %.1f A 12 12 0 1 0 %.1f %.1f Z\" fill=\"#007aff\" opacity=\"0.25\"/>", px - 12, py, px + 12, py, px - 12, py))
            paths.append(String(format: "<path d=\"M %.1f %.1f A 7 7 0 1 0 %.1f %.1f A 7 7 0 1 0 %.1f %.1f Z\" fill=\"#ffffff\"/>", px - 7, py, px + 7, py, px - 7, py))
            paths.append(String(format: "<path d=\"M %.1f %.1f A 5 5 0 1 0 %.1f %.1f A 5 5 0 1 0 %.1f %.1f Z\" fill=\"#007aff\"/>", px - 5, py, px + 5, py, px - 5, py))
        }
        for item in items where item.kind == .view {
            guard let view = item.view else { continue }
            let (px, py) = project(item.coordinate)
            views.append(Placed(view: view, x: px, y: py))
            if let title = item.title, !title.isEmpty {
                labels.append(Label(text: title, x: px, y: py + 22))
            }
        }
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(t(width)) \(t(height))\">\n\(paths.joined(separator: "\n"))\n</svg>"
        return Layout(svg: svg, labels: labels, views: views)
    }

    static func t(_ v: Double) -> String {
        let r = (v * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(format: "%.1f", r)
    }

    static func hex(_ color: Color, _ environment: EnvironmentValues) -> String {
        let c = color.resolve(in: environment)
        return String(format: "#%02x%02x%02x", Int((max(0, min(1, Double(c.red))) * 255).rounded()), Int((max(0, min(1, Double(c.green))) * 255).rounded()), Int((max(0, min(1, Double(c.blue))) * 255).rounded()))
    }

    /// The words of a label view, for a marker labelled by a view.
    static func plainText<V: View>(of view: V) -> String? {
        let description = String(describing: view)
        guard description.contains("Text") else { return nil }
        return description.components(separatedBy: "\"").dropFirst().first
    }
}
