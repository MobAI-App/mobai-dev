// MobAI curated stand-in: Charts
// Managed by the engine while unchanged; edit it and it is yours.
//
// Apple's Charts framework for the preview. Marks keep their public
// construction and modifier surface and CARRY THEIR DATA: the chart reduces
// its content to a list of marks, scales them into its plot area and draws
// them as one vector (PreviewVector), with axis labels as real text so the
// accessibility tree and the paint host both see them. Selection, gestures
// and annotations compile and do nothing. Not covered: sector marks (pie and
// donut), 3D charts, scrolling charts and per-mark annotations.

import Foundation
import SwiftUI

// MARK: - Plottable values

public protocol Plottable {
    var previewPlotValue: Double { get }
    var previewPlotLabel: String? { get }
}

extension Plottable {
    public var previewPlotLabel: String? { nil }
}

extension Date: Plottable {
    public var previewPlotValue: Double { timeIntervalSince1970 }
}
extension Double: Plottable {
    public var previewPlotValue: Double { self }
}
extension Float: Plottable {
    public var previewPlotValue: Double { Double(self) }
}
extension CGFloat: Plottable {
    public var previewPlotValue: Double { Double(self) }
}
extension Int: Plottable {
    public var previewPlotValue: Double { Double(self) }
}
extension Int64: Plottable {
    public var previewPlotValue: Double { Double(self) }
}
extension String: Plottable {
    public var previewPlotValue: Double { 0 }
    public var previewPlotLabel: String? { self }
}

public struct PlottableValue<Value: Plottable> {
    public let label: String
    public let value: Value

    private init(label: String, value: Value) {
        self.label = label
        self.value = value
    }

    public static func value(_ label: LocalizedStringKey, _ value: Value) -> Self {
        Self(label: "\(label)", value: value)
    }

    public static func value<S: StringProtocol>(_ label: S, _ value: Value) -> Self {
        Self(label: String(label), value: value)
    }

    public static func value(
        _ label: LocalizedStringKey, _ value: Date, unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self where Value == Date {
        Self(label: "\(label)", value: value)
    }

    public static func value<S: StringProtocol>(
        _ label: S, _ value: Date, unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self where Value == Date {
        Self(label: String(label), value: value)
    }

    var point: PlotPoint { PlotPoint(value: value.previewPlotValue, category: value.previewPlotLabel) }
}

/// One coordinate: a number, or a category that the chart orders by first
/// appearance.
public struct PlotPoint: Equatable, Sendable {
    public var value: Double
    public var category: String?
}

// MARK: - Marks

public struct PreviewMark {
    public enum Kind { case area, line, bar, rectangle, rule, point }
    public var kind: Kind
    public var x: PlotPoint?
    public var xEnd: PlotPoint?
    public var y: PlotPoint?
    public var yStart: PlotPoint?
    public var yEnd: PlotPoint?
    public var series: String?
    public var color: Color?
    public var opacity: Double = 1
    public var lineWidth: Double = 2
    public var dash: [Double] = []
    public var symbol = false
    public var smooth = false
    public var cornerRadius: Double = 0
}

public protocol ChartContent {
    var previewMarks: [PreviewMark] { get }
}

/// Every piece of chart content reduces to this.
public struct MarkGroup: ChartContent {
    public var previewMarks: [PreviewMark]
    public init(_ marks: [PreviewMark]) { previewMarks = marks }
}

public struct AreaMark: ChartContent {
    public var previewMarks: [PreviewMark]
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>, stacking: MarkStackingMethod = .standard) {
        previewMarks = [PreviewMark(kind: .area, x: x.point, y: y.point)]
    }
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, yStart: PlottableValue<Y>, yEnd: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .area, x: x.point, yStart: yStart.point, yEnd: yEnd.point)]
    }
    public init<X: Plottable, Y: Plottable, S: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>, series: PlottableValue<S>, stacking: MarkStackingMethod = .standard) {
        previewMarks = [PreviewMark(kind: .area, x: x.point, y: y.point, series: series.point.category ?? "\(series.point.value)")]
    }
}

public struct LineMark: ChartContent {
    public var previewMarks: [PreviewMark]
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .line, x: x.point, y: y.point)]
    }
    public init<X: Plottable, Y: Plottable, S: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>, series: PlottableValue<S>) {
        previewMarks = [PreviewMark(kind: .line, x: x.point, y: y.point, series: series.point.category ?? "\(series.point.value)")]
    }
}

public struct BarMark: ChartContent {
    public var previewMarks: [PreviewMark]
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>, width: MarkDimension = .automatic, height: MarkDimension = .automatic, stacking: MarkStackingMethod = .standard) {
        previewMarks = [PreviewMark(kind: .bar, x: x.point, y: y.point)]
    }
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, yStart: PlottableValue<Y>, yEnd: PlottableValue<Y>, width: MarkDimension = .automatic) {
        previewMarks = [PreviewMark(kind: .bar, x: x.point, yStart: yStart.point, yEnd: yEnd.point)]
    }
    public init<X: Plottable, Y: Plottable>(xStart: PlottableValue<X>, xEnd: PlottableValue<X>, y: PlottableValue<Y>, height: MarkDimension = .automatic) {
        previewMarks = [PreviewMark(kind: .rectangle, x: xStart.point, xEnd: xEnd.point, y: y.point)]
    }
    public init<X: Plottable>(x: PlottableValue<X>, width: MarkDimension = .automatic, height: MarkDimension = .automatic, stacking: MarkStackingMethod = .standard) {
        previewMarks = [PreviewMark(kind: .bar, x: x.point, y: PlotPoint(value: 1, category: nil))]
    }
}

public struct PointMark: ChartContent {
    public var previewMarks: [PreviewMark]
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .point, x: x.point, y: y.point, symbol: true)]
    }
}

public struct RuleMark: ChartContent {
    public var previewMarks: [PreviewMark]
    public init<X: Plottable>(x: PlottableValue<X>) {
        previewMarks = [PreviewMark(kind: .rule, x: x.point, lineWidth: 1)]
    }
    public init<Y: Plottable>(y: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .rule, y: y.point, lineWidth: 1)]
    }
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, yStart: PlottableValue<Y>, yEnd: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .rule, x: x.point, yStart: yStart.point, yEnd: yEnd.point, lineWidth: 1)]
    }
    public init<X: Plottable, Y: Plottable>(xStart: PlottableValue<X>, xEnd: PlottableValue<X>, y: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .rule, x: xStart.point, xEnd: xEnd.point, y: y.point, lineWidth: 1)]
    }
}

public struct RectangleMark: ChartContent {
    public var previewMarks: [PreviewMark]
    public init<X: Plottable, Y: Plottable>(xStart: PlottableValue<X>, xEnd: PlottableValue<X>, yStart: PlottableValue<Y>, yEnd: PlottableValue<Y>) {
        previewMarks = [PreviewMark(kind: .rectangle, x: xStart.point, xEnd: xEnd.point, yStart: yStart.point, yEnd: yEnd.point)]
    }
    public init<X: Plottable, Y: Plottable>(x: PlottableValue<X>, y: PlottableValue<Y>, width: MarkDimension = .automatic, height: MarkDimension = .automatic) {
        previewMarks = [PreviewMark(kind: .point, x: x.point, y: y.point, symbol: true)]
    }
    public init<X: Plottable>(xStart: PlottableValue<X>, xEnd: PlottableValue<X>) {
        previewMarks = [PreviewMark(kind: .rectangle, x: xStart.point, xEnd: xEnd.point)]
    }
}

public struct MarkDimension: Hashable, Sendable {
    public init() {}
    public static let automatic = MarkDimension()
    public static func fixed(_ size: CGFloat) -> MarkDimension { MarkDimension() }
    public static func ratio(_ ratio: CGFloat) -> MarkDimension { MarkDimension() }
    public static func inset(_ inset: CGFloat) -> MarkDimension { MarkDimension() }
}

public struct MarkStackingMethod: Hashable, Sendable {
    public init() {}
    public static let standard = MarkStackingMethod()
    public static let normalized = MarkStackingMethod()
    public static let center = MarkStackingMethod()
    public static let unstacked = MarkStackingMethod()
}

public struct InterpolationMethod: Hashable, Sendable {
    let smooth: Bool
    public static let linear = InterpolationMethod(smooth: false)
    public static let catmullRom = InterpolationMethod(smooth: true)
    public static let cardinal = InterpolationMethod(smooth: true)
    public static let monotone = InterpolationMethod(smooth: true)
    public static let stepStart = InterpolationMethod(smooth: false)
    public static let stepCenter = InterpolationMethod(smooth: false)
    public static let stepEnd = InterpolationMethod(smooth: false)
    public static func catmullRom(alpha: CGFloat) -> InterpolationMethod { .catmullRom }
    public static func cardinal(tension: CGFloat) -> InterpolationMethod { .cardinal }
}

public struct BasicChartSymbolShape: Hashable, Sendable {
    public init() {}
    public static let circle = BasicChartSymbolShape()
    public static let square = BasicChartSymbolShape()
    public static let triangle = BasicChartSymbolShape()
    public static let diamond = BasicChartSymbolShape()
    public static let pentagon = BasicChartSymbolShape()
    public static let plus = BasicChartSymbolShape()
    public static let cross = BasicChartSymbolShape()
    public static let asterisk = BasicChartSymbolShape()
}

public struct AnnotationPosition: Hashable, Sendable {
    public init() {}
    public static let automatic = AnnotationPosition()
    public static let overlay = AnnotationPosition()
    public static let top = AnnotationPosition()
    public static let bottom = AnnotationPosition()
    public static let leading = AnnotationPosition()
    public static let trailing = AnnotationPosition()
    public static let topLeading = AnnotationPosition()
    public static let topTrailing = AnnotationPosition()
    public static let bottomLeading = AnnotationPosition()
    public static let bottomTrailing = AnnotationPosition()
}

public struct AnnotationOverflowResolution: Hashable, Sendable {
    public init() {}
    public static let automatic = AnnotationOverflowResolution()
}

/// Mark modifiers. Each returns the reduced marks with the change applied,
/// which is why `foregroundStyle(.red).symbol(.circle)` chains on anything.
extension ChartContent {
    public func foregroundStyle<S: ShapeStyle>(_ style: S) -> MarkGroup {
        map { mark in
            var m = mark
            if let color = style as? Color { m.color = color }
            return m
        }
    }
    public func foregroundStyle<D: Plottable>(by value: PlottableValue<D>) -> MarkGroup {
        map { mark in
            var m = mark
            m.series = value.point.category ?? "\(value.point.value)"
            return m
        }
    }
    public func interpolationMethod(_ method: InterpolationMethod) -> MarkGroup {
        map { mark in
            var m = mark
            m.smooth = method.smooth
            return m
        }
    }
    public func lineStyle(_ style: StrokeStyle) -> MarkGroup {
        map { mark in
            var m = mark
            m.lineWidth = Double(style.lineWidth)
            m.dash = style.dash.map(Double.init)
            return m
        }
    }
    public func symbol(_ shape: BasicChartSymbolShape) -> MarkGroup {
        map { mark in
            var m = mark
            m.symbol = true
            return m
        }
    }
    public func symbol<S: View>(@ViewBuilder _ symbol: () -> S) -> MarkGroup { self.symbol(.circle) }
    public func symbol<D: Plottable>(by value: PlottableValue<D>) -> MarkGroup { self.symbol(.circle) }
    public func symbolSize(_ size: CGFloat) -> MarkGroup { MarkGroup(previewMarks) }
    public func symbolSize(_ size: CGSize) -> MarkGroup { MarkGroup(previewMarks) }
    public func opacity(_ opacity: Double) -> MarkGroup {
        map { mark in
            var m = mark
            m.opacity = opacity
            return m
        }
    }
    public func cornerRadius(_ radius: CGFloat, style: RoundedCornerStyle = .continuous) -> MarkGroup {
        map { mark in
            var m = mark
            m.cornerRadius = Double(radius)
            return m
        }
    }
    public func clipShape<S: Shape>(_ shape: S) -> MarkGroup { MarkGroup(previewMarks) }
    public func annotation<C: View>(position: AnnotationPosition = .automatic, alignment: Alignment = .center, spacing: CGFloat? = nil, overflowResolution: AnnotationOverflowResolution = .automatic, @ViewBuilder content: () -> C) -> MarkGroup { MarkGroup(previewMarks) }
    public func annotation<C: View>(position: AnnotationPosition = .automatic, alignment: Alignment = .center, spacing: CGFloat? = nil, overflowResolution: AnnotationOverflowResolution = .automatic, @ViewBuilder content: (AnnotationContext) -> C) -> MarkGroup { MarkGroup(previewMarks) }
    public func position<D: Plottable>(by value: PlottableValue<D>, axis: Axis? = nil, span: MarkDimension = .automatic) -> MarkGroup { MarkGroup(previewMarks) }
    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> MarkGroup { MarkGroup(previewMarks) }
    public func zIndex(_ value: Double) -> MarkGroup { MarkGroup(previewMarks) }
    public func accessibilityLabel(_ label: String) -> MarkGroup { MarkGroup(previewMarks) }
    public func accessibilityValue(_ value: String) -> MarkGroup { MarkGroup(previewMarks) }
    public func accessibilityHidden(_ hidden: Bool) -> MarkGroup { MarkGroup(previewMarks) }
    public func mask<C: ChartContent>(@ChartContentBuilder content: () -> C) -> MarkGroup { MarkGroup(previewMarks) }

    private func map(_ transform: (PreviewMark) -> PreviewMark) -> MarkGroup {
        MarkGroup(previewMarks.map(transform))
    }
}

public struct AnnotationContext {
    public var targetSize: CGSize = .zero
}

extension ForEach: ChartContent where Content: ChartContent {
    public var previewMarks: [PreviewMark] {
        data.flatMap { content($0).previewMarks }
    }

    // The initializers Charts adds to ForEach for chart content; SwiftUI's
    // own require a View. They reach the engine's ForEach through its
    // unconstrained `_previewData` initializers.
    public init(_ data: Data, @ChartContentBuilder content: @escaping (Data.Element) -> Content) where ID == Data.Element.ID, Data.Element: Identifiable {
        self.init(_previewData: data, content: content)
    }
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ChartContentBuilder content: @escaping (Data.Element) -> Content) {
        self.init(_previewData: data, id: id, content: content)
    }
    public init(_ data: Range<Int>, @ChartContentBuilder content: @escaping (Int) -> Content) where Data == Range<Int>, ID == Int {
        self.init(_previewData: data, id: \.self, content: content)
    }
}

extension Optional: ChartContent where Wrapped: ChartContent {
    public var previewMarks: [PreviewMark] { self?.previewMarks ?? [] }
}

extension Never: ChartContent {
    public var previewMarks: [PreviewMark] { [] }
}
extension Never: AxisMark {}
extension Never: AxisContent {
    public var previewAxis: AxisSpec { AxisSpec() }
}

@resultBuilder
public enum ChartContentBuilder {
    public static func buildExpression<C: ChartContent>(_ content: C) -> MarkGroup { MarkGroup(content.previewMarks) }
    public static func buildBlock(_ parts: MarkGroup...) -> MarkGroup { MarkGroup(parts.flatMap(\.previewMarks)) }
    public static func buildOptional(_ part: MarkGroup?) -> MarkGroup { part ?? MarkGroup([]) }
    public static func buildEither(first: MarkGroup) -> MarkGroup { first }
    public static func buildEither(second: MarkGroup) -> MarkGroup { second }
    public static func buildArray(_ parts: [MarkGroup]) -> MarkGroup { MarkGroup(parts.flatMap(\.previewMarks)) }
    public static func buildLimitedAvailability(_ part: MarkGroup) -> MarkGroup { part }
}

// MARK: - Axes

public protocol AxisContent {
    var previewAxis: AxisSpec { get }
}
public protocol AxisMark {
    var previewLabel: AxisLabelSpec? { get }
}
public extension AxisMark {
    var previewLabel: AxisLabelSpec? { nil }
}

/// What an axis draws: which values, and how a value is written.
public struct AxisSpec {
    public var hidden = false
    public var position: AxisMarkPosition = .automatic
    public var values: [PlotPoint]? = nil
    public var stride: (component: Calendar.Component, count: Int)? = nil
    public var label: AxisLabelSpec? = nil
    public var gridLines = true
    public init() {}
}

public struct AxisLabelSpec {
    public var dateFormat: Date.FormatStyle? = nil
    public var numberFormat: FloatingPointFormatStyle<Double>? = nil
    public var text: ((AxisValue) -> String)? = nil
    public var hidden = false
    public init() {}
}

public struct AxisMarkPosition: Hashable, Sendable {
    public init() {}
    public static let automatic = AxisMarkPosition()
    public static let leading = AxisMarkPosition()
    public static let trailing = AxisMarkPosition()
    public static let top = AxisMarkPosition()
    public static let bottom = AxisMarkPosition()
}

public struct AxisMarkPreset: Hashable, Sendable {
    public init() {}
    public static let automatic = AxisMarkPreset()
    public static let aligned = AxisMarkPreset()
    public static let extended = AxisMarkPreset()
}

/// The value an axis mark is placed at, as Charts hands it to the content
/// closure.
public struct AxisValue {
    public let point: PlotPoint
    public let index: Int
    public let count: Int

    public func `as`<P: Plottable>(_ type: P.Type) -> P? {
        if P.self == Date.self { return Date(timeIntervalSince1970: point.value) as? P }
        if P.self == Double.self { return point.value as? P }
        if P.self == Int.self { return Int(point.value.rounded()) as? P }
        if P.self == String.self { return point.category as? P }
        return nil
    }
}

public struct AxisMarkValues: Sendable {
    var points: [PlotPoint]?
    var stride: (Calendar.Component, Int)?
    var desiredCount: Int?
    public static let automatic = AxisMarkValues(points: nil, stride: nil, desiredCount: nil)
    public static func automatic(desiredCount: Int? = nil, roundLowerBound: Bool? = nil, roundUpperBound: Bool? = nil) -> AxisMarkValues {
        AxisMarkValues(points: nil, stride: nil, desiredCount: desiredCount)
    }
    public static func stride(by component: Calendar.Component, count: Int = 1, roundLowerBound: Bool? = nil, roundUpperBound: Bool? = nil, calendar: Calendar? = nil) -> AxisMarkValues {
        AxisMarkValues(points: nil, stride: (component, count), desiredCount: nil)
    }
    public static func stride<D: BinaryFloatingPoint>(by stride: D, roundLowerBound: Bool? = nil, roundUpperBound: Bool? = nil) -> AxisMarkValues {
        AxisMarkValues(points: nil, stride: nil, desiredCount: nil)
    }
    public static func stride<D: BinaryInteger>(by stride: D, roundLowerBound: Bool? = nil, roundUpperBound: Bool? = nil) -> AxisMarkValues {
        AxisMarkValues(points: nil, stride: nil, desiredCount: nil)
    }
}

public struct AxisMarks<Content: AxisMark>: AxisContent {
    public var previewAxis: AxisSpec

    public init(preset: AxisMarkPreset = .automatic, position: AxisMarkPosition = .automatic, values: AxisMarkValues = .automatic, stroke: StrokeStyle? = nil) where Content == Never {
        var spec = AxisSpec()
        spec.position = position
        spec.values = values.points
        spec.stride = values.stride.map { (component: $0.0, count: $0.1) }
        previewAxis = spec
    }
    public init<V: Plottable>(preset: AxisMarkPreset = .automatic, position: AxisMarkPosition = .automatic, values: [V], stroke: StrokeStyle? = nil) where Content == Never {
        var spec = AxisSpec()
        spec.position = position
        spec.values = values.map { PlotPoint(value: $0.previewPlotValue, category: $0.previewPlotLabel) }
        previewAxis = spec
    }
    public init(preset: AxisMarkPreset = .automatic, position: AxisMarkPosition = .automatic, values: AxisMarkValues = .automatic, stroke: StrokeStyle? = nil, @AxisMarkBuilder content: @escaping (AxisValue) -> Content) {
        var spec = AxisSpec()
        spec.position = position
        spec.values = values.points
        spec.stride = values.stride.map { (component: $0.0, count: $0.1) }
        // The closure is probed once with a representative value to learn
        // the label's format; it is called again per tick when it formats
        // text itself.
        let probe = content(AxisValue(point: PlotPoint(value: Date().timeIntervalSince1970, category: nil), index: 0, count: 1))
        var label = probe.previewLabel
        if var l = label, l.text != nil {
            l.text = { value in content(value).previewLabel?.text?(value) ?? "" }
            label = l
        }
        spec.label = label
        previewAxis = spec
    }
    public init<V: Plottable>(preset: AxisMarkPreset = .automatic, position: AxisMarkPosition = .automatic, values: [V], stroke: StrokeStyle? = nil, @AxisMarkBuilder content: @escaping (AxisValue) -> Content) {
        var spec = AxisSpec()
        spec.position = position
        spec.values = values.map { PlotPoint(value: $0.previewPlotValue, category: $0.previewPlotLabel) }
        let probe = content(AxisValue(point: spec.values?.first ?? PlotPoint(value: 0, category: nil), index: 0, count: max(1, values.count)))
        var label = probe.previewLabel
        if var l = label, l.text != nil {
            l.text = { value in content(value).previewLabel?.text?(value) ?? "" }
            label = l
        }
        spec.label = label
        previewAxis = spec
    }
}

public struct AxisMarkGroup: AxisMark {
    public var previewLabel: AxisLabelSpec?
}

@resultBuilder
public enum AxisMarkBuilder {
    public static func buildExpression<M: AxisMark>(_ mark: M) -> AxisMarkGroup { AxisMarkGroup(previewLabel: mark.previewLabel) }
    public static func buildBlock(_ parts: AxisMarkGroup...) -> AxisMarkGroup {
        AxisMarkGroup(previewLabel: parts.compactMap(\.previewLabel).first)
    }
    public static func buildOptional(_ part: AxisMarkGroup?) -> AxisMarkGroup { part ?? AxisMarkGroup(previewLabel: nil) }
    public static func buildEither(first: AxisMarkGroup) -> AxisMarkGroup { first }
    public static func buildEither(second: AxisMarkGroup) -> AxisMarkGroup { second }
}

@resultBuilder
public enum AxisContentBuilder {
    public static func buildBlock<C: AxisContent>(_ content: C) -> C { content }
    public static func buildBlock<A: AxisContent, B: AxisContent>(_ a: A, _ b: B) -> A { a }
}

public struct AxisValueLabel<Content: View>: AxisMark {
    public var previewLabel: AxisLabelSpec?

    public init(centered: Bool? = nil, anchor: UnitPoint? = nil, multiLabelAlignment: Alignment? = nil, collisionResolution: AxisValueLabelCollisionResolution = .automatic, offsetsMarks: Bool? = nil, orientation: AxisValueLabelOrientation = .automatic, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil) where Content == Never {
        previewLabel = AxisLabelSpec()
    }
    public init(format: Date.FormatStyle, centered: Bool? = nil, anchor: UnitPoint? = nil, multiLabelAlignment: Alignment? = nil, collisionResolution: AxisValueLabelCollisionResolution = .automatic, offsetsMarks: Bool? = nil, orientation: AxisValueLabelOrientation = .automatic, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil) where Content == Never {
        var spec = AxisLabelSpec()
        spec.dateFormat = format
        previewLabel = spec
    }
    public init(format: FloatingPointFormatStyle<Double>, centered: Bool? = nil, anchor: UnitPoint? = nil, multiLabelAlignment: Alignment? = nil, collisionResolution: AxisValueLabelCollisionResolution = .automatic, offsetsMarks: Bool? = nil, orientation: AxisValueLabelOrientation = .automatic, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil) where Content == Never {
        var spec = AxisLabelSpec()
        spec.numberFormat = format
        previewLabel = spec
    }
    public init(_ label: LocalizedStringKey, centered: Bool? = nil, anchor: UnitPoint? = nil, multiLabelAlignment: Alignment? = nil, collisionResolution: AxisValueLabelCollisionResolution = .automatic, offsetsMarks: Bool? = nil, orientation: AxisValueLabelOrientation = .automatic, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil) where Content == Never {
        var spec = AxisLabelSpec()
        spec.text = { _ in "\(label)" }
        previewLabel = spec
    }
    public init(centered: Bool? = nil, anchor: UnitPoint? = nil, multiLabelAlignment: Alignment? = nil, collisionResolution: AxisValueLabelCollisionResolution = .automatic, offsetsMarks: Bool? = nil, orientation: AxisValueLabelOrientation = .automatic, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        var spec = AxisLabelSpec()
        let made = content()
        spec.text = { _ in PreviewCharts.plainText(of: made) }
        previewLabel = spec
    }
}

public struct AxisValueLabelCollisionResolution: Hashable, Sendable {
    public init() {}
    public static let automatic = AxisValueLabelCollisionResolution()
    public static let greedy = AxisValueLabelCollisionResolution()
    public static let disabled = AxisValueLabelCollisionResolution()
    public static func truncate(minimumSize: CGFloat? = nil) -> AxisValueLabelCollisionResolution { AxisValueLabelCollisionResolution() }
}

public struct AxisValueLabelOrientation: Hashable, Sendable {
    public init() {}
    public static let automatic = AxisValueLabelOrientation()
    public static let horizontal = AxisValueLabelOrientation()
    public static let vertical = AxisValueLabelOrientation()
    public static let verticalReversed = AxisValueLabelOrientation()
}

public struct AxisGridLine: AxisMark {
    public init(centered: Bool? = nil, stroke: StrokeStyle? = nil) {}
}
public struct AxisTick: AxisMark {
    public init(centered: Bool? = nil, length: CGFloat? = nil, stroke: StrokeStyle? = nil) {}
    public init(centered: Bool? = nil, length: AxisTickLength, stroke: StrokeStyle? = nil) {}
}
public struct AxisTickLength: Hashable, Sendable {
    public init() {}
    public static let automatic = AxisTickLength()
    public static let label = AxisTickLength()
    public static let longestLabel = AxisTickLength()
}

// MARK: - Scales and proxies

public struct PlotDimensionScaleRange: Hashable, Sendable {
    public var startPadding: Double = 0
    public var endPadding: Double = 0
    public init() {}
    public static func plotDimension(padding: CGFloat = 0) -> PlotDimensionScaleRange {
        var r = PlotDimensionScaleRange()
        r.startPadding = Double(padding)
        r.endPadding = Double(padding)
        return r
    }
    public static func plotDimension(startPadding: CGFloat = 0, endPadding: CGFloat = 0) -> PlotDimensionScaleRange {
        var r = PlotDimensionScaleRange()
        r.startPadding = Double(startPadding)
        r.endPadding = Double(endPadding)
        return r
    }
}

public struct ScaleType: Hashable, Sendable {
    public init() {}
    public static let linear = ScaleType()
    public static let log = ScaleType()
    public static let date = ScaleType()
    public static let category = ScaleType()
    public static let symmetricLog = ScaleType()
    public static let squareRoot = ScaleType()
}

public struct ScaleDomain: Hashable, Sendable {
    public init() {}
    public static let automatic = ScaleDomain()
    public static func automatic(includesZero: Bool? = nil, reversed: Bool? = nil) -> ScaleDomain { ScaleDomain() }
}

/// Positions the chart hands back to overlays: the same projection the marks
/// were drawn with.
public struct ChartProxy {
    let scales: PreviewCharts.Scales?
    public var plotAreaSize: CGSize { scales.map { CGSize(width: $0.plot.width, height: $0.plot.height) } ?? .zero }
    public var plotSize: CGSize { plotAreaSize }
    public var plotAreaFrame: Anchor<CGRect>? { nil }
    public var plotFrame: Anchor<CGRect>? { nil }
    public var plotContainerFrame: Anchor<CGRect>? { nil }

    public func position<P: Plottable>(forX value: P) -> CGFloat? {
        scales.map { CGFloat($0.x(PlotPoint(value: value.previewPlotValue, category: value.previewPlotLabel)) - $0.plot.minX) }
    }
    public func position<P: Plottable>(forY value: P) -> CGFloat? {
        scales.map { CGFloat($0.y(value.previewPlotValue) - $0.plot.minY) }
    }
    public func position<X: Plottable, Y: Plottable>(for value: (x: X, y: Y)) -> CGPoint? {
        guard let x = position(forX: value.x), let y = position(forY: value.y) else { return nil }
        return CGPoint(x: x, y: y)
    }
    public func value<P: Plottable>(atX x: CGFloat, as type: P.Type = P.self) -> P? {
        guard let scales, scales.plot.width > 0 else { return nil }
        let t = Double(x) / scales.plot.width
        let v = scales.xDomain.lowerBound + t * (scales.xDomain.upperBound - scales.xDomain.lowerBound)
        return AxisValue(point: PlotPoint(value: v, category: nil), index: 0, count: 1).as(type)
    }
    public func value<P: Plottable>(atY y: CGFloat, as type: P.Type = P.self) -> P? {
        guard let scales, scales.plot.height > 0 else { return nil }
        let t = 1 - Double(y) / scales.plot.height
        let v = scales.yDomain.lowerBound + t * (scales.yDomain.upperBound - scales.yDomain.lowerBound)
        return AxisValue(point: PlotPoint(value: v, category: nil), index: 0, count: 1).as(type)
    }
    public func value<X: Plottable, Y: Plottable>(at point: CGPoint, as type: (X, Y).Type = (X, Y).self) -> (X, Y)? {
        guard let x: X = value(atX: point.x), let y: Y = value(atY: point.y) else { return nil }
        return (x, y)
    }
}

// MARK: - Chart

public struct Chart<Content: ChartContent>: View {
    private var marks: [PreviewMark]
    private var options = PreviewCharts.Options()
    private var overlays: [(ChartProxy) -> AnyView] = []
    private var backgrounds: [(ChartProxy) -> AnyView] = []

    @Environment(\.colorScheme) private var colorScheme

    public init(@ChartContentBuilder content: () -> Content) {
        marks = content().previewMarks
    }

    public init<Data: RandomAccessCollection, C: ChartContent>(_ data: Data, @ChartContentBuilder content: (Data.Element) -> C) where Content == ForEach<Data, Data.Element.ID, C>, Data.Element: Identifiable {
        marks = data.flatMap { content($0).previewMarks }
    }

    public init<Data: RandomAccessCollection, ID: Hashable, C: ChartContent>(_ data: Data, id: KeyPath<Data.Element, ID>, @ChartContentBuilder content: (Data.Element) -> C) where Content == ForEach<Data, ID, C> {
        marks = data.flatMap { content($0).previewMarks }
    }

    public var body: some View {
        GeometryReader { proxy in
            let layout = PreviewCharts.layout(marks: marks, options: options, size: proxy.size, scheme: colorScheme)
            ZStack(alignment: .topLeading) {
                ForEach(Array(backgrounds.enumerated()), id: \.offset) { item in
                    item.element(ChartProxy(scales: layout.scales))
                }
                PreviewVector(svg: layout.svg)
                    .frame(width: layout.scales.plot.width, height: layout.scales.plot.height)
                    .position(x: layout.scales.plot.midX, y: layout.scales.plot.midY)
                ForEach(Array(layout.labels.enumerated()), id: \.offset) { item in
                    Text(item.element.text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: item.element.x, y: item.element.y)
                }
                ForEach(Array(overlays.enumerated()), id: \.offset) { item in
                    item.element(ChartProxy(scales: layout.scales))
                        .frame(width: layout.scales.plot.width, height: layout.scales.plot.height)
                        .position(x: layout.scales.plot.midX, y: layout.scales.plot.midY)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .accessibilityLabel("Chart")
    }

    private func with(_ change: (inout Chart) -> Void) -> Chart {
        var copy = self
        change(&copy)
        return copy
    }

    // Chart-level modifiers. Declared on Chart so a chain stays a Chart and
    // every later one still reaches the options; the View copies below are
    // for a chain that already became `some View`.
    public func chartLegend(_ visibility: Visibility) -> Chart { self }
    public func chartLegend(position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil) -> Chart { self }
    public func chartLegend<C: View>(position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil, @ViewBuilder content: () -> C) -> Chart { self }
    public func chartXAxis(_ visibility: Visibility) -> Chart { with { $0.options.xAxis.hidden = visibility == .hidden } }
    public func chartYAxis(_ visibility: Visibility) -> Chart { with { $0.options.yAxis.hidden = visibility == .hidden } }
    public func chartXAxis<C: AxisContent>(@AxisContentBuilder content: () -> C) -> Chart {
        let spec = content().previewAxis
        return with { $0.options.xAxis = spec }
    }
    public func chartYAxis<C: AxisContent>(@AxisContentBuilder content: () -> C) -> Chart {
        let spec = content().previewAxis
        return with { $0.options.yAxis = spec }
    }
    public func chartXAxisLabel(_ label: String, position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil) -> Chart { self }
    public func chartYAxisLabel(_ label: String, position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil) -> Chart { self }
    public func chartXAxisLabel<C: View>(position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil, @ViewBuilder content: () -> C) -> Chart { self }
    public func chartYAxisLabel<C: View>(position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil, @ViewBuilder content: () -> C) -> Chart { self }
    public func chartXScale<P: Plottable>(domain: ClosedRange<P>, type: ScaleType? = nil) -> Chart {
        with { $0.options.xDomain = domain.lowerBound.previewPlotValue...domain.upperBound.previewPlotValue }
    }
    public func chartXScale<P: Plottable>(domain: [P], type: ScaleType? = nil) -> Chart {
        with { $0.options.xCategories = domain.compactMap(\.previewPlotLabel) }
    }
    public func chartXScale(domain: ScaleDomain, type: ScaleType? = nil) -> Chart { self }
    public func chartXScale(range: PlotDimensionScaleRange) -> Chart { with { $0.options.xRange = range } }
    public func chartXScale<P: Plottable>(domain: ClosedRange<P>, range: PlotDimensionScaleRange, type: ScaleType? = nil) -> Chart {
        with {
            $0.options.xDomain = domain.lowerBound.previewPlotValue...domain.upperBound.previewPlotValue
            $0.options.xRange = range
        }
    }
    public func chartYScale<P: Plottable>(domain: ClosedRange<P>, type: ScaleType? = nil) -> Chart {
        with { $0.options.yDomain = domain.lowerBound.previewPlotValue...domain.upperBound.previewPlotValue }
    }
    public func chartYScale(domain: ScaleDomain, type: ScaleType? = nil) -> Chart { self }
    public func chartYScale(range: PlotDimensionScaleRange) -> Chart { self }
    public func chartYScale<P: Plottable>(domain: ClosedRange<P>, range: PlotDimensionScaleRange, type: ScaleType? = nil) -> Chart {
        with { $0.options.yDomain = domain.lowerBound.previewPlotValue...domain.upperBound.previewPlotValue }
    }
    public func chartXSelection<P: Plottable>(value: Binding<P?>) -> Chart { self }
    public func chartYSelection<P: Plottable>(value: Binding<P?>) -> Chart { self }
    public func chartXSelection<P: Plottable>(range: Binding<ClosedRange<P>?>) -> Chart { self }
    public func chartAngleSelection<P: Plottable>(value: Binding<P?>) -> Chart { self }
    public func chartOverlay<C: View>(alignment: Alignment = .center, @ViewBuilder content: @escaping (ChartProxy) -> C) -> Chart {
        with { $0.overlays.append { AnyView(content($0)) } }
    }
    public func chartBackground<C: View>(alignment: Alignment = .center, @ViewBuilder content: @escaping (ChartProxy) -> C) -> Chart {
        with { $0.backgrounds.append { AnyView(content($0)) } }
    }
    public func chartPlotStyle<C: View>(@ViewBuilder content: @escaping (ChartPlotContent) -> C) -> Chart { self }
    public func chartForegroundStyleScale<D: Plottable & Hashable, S: ShapeStyle>(_ mapping: KeyValuePairs<D, S>) -> Chart {
        with { chart in
            for (key, style) in mapping {
                if let color = style as? Color {
                    chart.options.seriesColors[key.previewPlotLabel ?? "\(key.previewPlotValue)"] = color
                }
            }
        }
    }
    public func chartForegroundStyleScale<D: Plottable & Hashable, S: ShapeStyle>(domain: [D], range: [S]) -> Chart {
        with { chart in
            for (key, style) in zip(domain, range) {
                if let color = style as? Color {
                    chart.options.seriesColors[key.previewPlotLabel ?? "\(key.previewPlotValue)"] = color
                }
            }
        }
    }
    public func chartForegroundStyleScale<S: ShapeStyle>(range: [S]) -> Chart { self }
    public func chartForegroundStyleScale(domain: ScaleDomain) -> Chart { self }
    public func chartSymbolScale<D: Plottable & Hashable>(_ mapping: KeyValuePairs<D, BasicChartSymbolShape>) -> Chart { self }
    public func chartScrollableAxes(_ axes: Axis.Set) -> Chart { self }
    public func chartXVisibleDomain<P: Plottable>(length: P) -> Chart { self }
    public func chartYVisibleDomain<P: Plottable>(length: P) -> Chart { self }
    public func chartScrollPosition<P: Plottable>(x: Binding<P>) -> Chart { self }
    public func chartScrollPosition<P: Plottable>(y: Binding<P>) -> Chart { self }
    public func chartScrollPosition(initialX: some Plottable) -> Chart { self }
    public func chartScrollPosition(initialY: some Plottable) -> Chart { self }
    public func chartScrollTargetBehavior(_ behavior: some Any) -> Chart { self }
    public func chartGesture<G: Gesture>(_ gesture: @escaping (ChartProxy) -> G) -> Chart { self }
    public func chartXAxisStyle<C: View>(@ViewBuilder content: @escaping (ChartAxisContent) -> C) -> Chart { self }
    public func chartYAxisStyle<C: View>(@ViewBuilder content: @escaping (ChartAxisContent) -> C) -> Chart { self }
}

public struct ChartPlotContent: View {
    public var body: some View { Color.clear }
}
public struct ChartAxisContent: View {
    public var body: some View { Color.clear }
}

/// The same modifiers on any view, for a chain that has already left the
/// Chart type (after `.frame`, `.padding`): they compile and change nothing.
extension View {
    public func chartLegend(_ visibility: Visibility) -> some View { self }
    public func chartLegend(position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil) -> some View { self }
    public func chartXAxis(_ visibility: Visibility) -> some View { self }
    public func chartYAxis(_ visibility: Visibility) -> some View { self }
    public func chartXAxis<C: AxisContent>(@AxisContentBuilder content: () -> C) -> some View { self }
    public func chartYAxis<C: AxisContent>(@AxisContentBuilder content: () -> C) -> some View { self }
    public func chartXAxisLabel(_ label: String, position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil) -> some View { self }
    public func chartYAxisLabel(_ label: String, position: AnnotationPosition = .automatic, alignment: Alignment? = nil, spacing: CGFloat? = nil) -> some View { self }
    public func chartXScale<P: Plottable>(domain: ClosedRange<P>, type: ScaleType? = nil) -> some View { self }
    public func chartXScale<P: Plottable>(domain: [P], type: ScaleType? = nil) -> some View { self }
    public func chartXScale(domain: ScaleDomain, type: ScaleType? = nil) -> some View { self }
    public func chartXScale(range: PlotDimensionScaleRange) -> some View { self }
    public func chartYScale<P: Plottable>(domain: ClosedRange<P>, type: ScaleType? = nil) -> some View { self }
    public func chartYScale(domain: ScaleDomain, type: ScaleType? = nil) -> some View { self }
    public func chartYScale(range: PlotDimensionScaleRange) -> some View { self }
    public func chartXSelection<P: Plottable>(value: Binding<P?>) -> some View { self }
    public func chartYSelection<P: Plottable>(value: Binding<P?>) -> some View { self }
    public func chartXSelection<P: Plottable>(range: Binding<ClosedRange<P>?>) -> some View { self }
    public func chartOverlay<C: View>(alignment: Alignment = .center, @ViewBuilder content: @escaping (ChartProxy) -> C) -> some View {
        overlay { content(ChartProxy(scales: nil)) }
    }
    public func chartBackground<C: View>(alignment: Alignment = .center, @ViewBuilder content: @escaping (ChartProxy) -> C) -> some View {
        background { content(ChartProxy(scales: nil)) }
    }
    public func chartPlotStyle<C: View>(@ViewBuilder content: @escaping (ChartPlotContent) -> C) -> some View { self }
    public func chartForegroundStyleScale<D: Plottable & Hashable, S: ShapeStyle>(_ mapping: KeyValuePairs<D, S>) -> some View { self }
    public func chartForegroundStyleScale<D: Plottable & Hashable, S: ShapeStyle>(domain: [D], range: [S]) -> some View { self }
    public func chartScrollableAxes(_ axes: Axis.Set) -> some View { self }
    public func chartXVisibleDomain<P: Plottable>(length: P) -> some View { self }
    public func chartScrollPosition<P: Plottable>(x: Binding<P>) -> some View { self }
    public func chartScrollPosition(initialX: some Plottable) -> some View { self }
    public func chartGesture<G: Gesture>(_ gesture: @escaping (ChartProxy) -> G) -> some View { self }
}

// MARK: - Layout and drawing

public enum PreviewCharts {
    struct Options {
        var xAxis = AxisSpec()
        var yAxis = AxisSpec()
        var xDomain: ClosedRange<Double>?
        var yDomain: ClosedRange<Double>?
        var xCategories: [String]?
        var xRange = PlotDimensionScaleRange()
        var seriesColors: [String: Color] = [:]
    }

    /// The projection of one laid-out chart.
    public struct Scales {
        public var plot: CGRect
        public var xDomain: ClosedRange<Double>
        public var yDomain: ClosedRange<Double>
        public var categories: [String]
        public var startPadding: Double
        public var endPadding: Double

        /// Categories take band centres; numbers map linearly across the
        /// padded plot width.
        public func x(_ point: PlotPoint) -> Double {
            if let category = point.category {
                let index = Double(categories.firstIndex(of: category) ?? 0)
                let count = Double(max(categories.count, 1))
                return plot.minX + (index + 0.5) / count * plot.width
            }
            let span = xDomain.upperBound - xDomain.lowerBound
            let usable = max(plot.width - startPadding - endPadding, 1)
            let t = span > 0 ? (point.value - xDomain.lowerBound) / span : 0.5
            return plot.minX + startPadding + t * usable
        }

        public func bandWidth() -> Double {
            plot.width / Double(max(categories.count, 1))
        }

        public func y(_ value: Double) -> Double {
            let span = yDomain.upperBound - yDomain.lowerBound
            let t = span > 0 ? (value - yDomain.lowerBound) / span : 0.5
            return plot.maxY - t * plot.height
        }
    }

    struct Label {
        var text: String
        var x: Double
        var y: Double
    }

    struct Layout {
        var scales: Scales
        var svg: String
        var labels: [Label]
    }

    static let palette: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .yellow, .pink]

    static func layout(marks: [PreviewMark], options: Options, size: CGSize, scheme: ColorScheme) -> Layout {
        let xVisible = !options.xAxis.hidden
        let yVisible = !options.yAxis.hidden
        let yLeading = options.yAxis.position == .leading
        let axisWidth: Double = yVisible ? 34 : 0
        let axisHeight: Double = xVisible ? 18 : 0
        let plot = CGRect(
            x: yLeading ? axisWidth : 0,
            y: 0,
            width: max(Double(size.width) - axisWidth, 1),
            height: max(Double(size.height) - axisHeight, 1))

        // Categories in order of first appearance; numeric domains from the
        // data, y always including zero (bars stand on it, and Charts does
        // the same for numbers), then rounded out to a tidy step.
        var categories = options.xCategories ?? []
        var xs: [Double] = []
        var ys: [Double] = []
        for mark in marks {
            for point in [mark.x, mark.xEnd].compactMap({ $0 }) {
                if let c = point.category {
                    if !categories.contains(c) { categories.append(c) }
                } else {
                    xs.append(point.value)
                }
            }
            for point in [mark.y, mark.yStart, mark.yEnd].compactMap({ $0 }) where point.category == nil {
                ys.append(point.value)
            }
        }
        var xDomain = options.xDomain ?? domain(xs, includeZero: false)
        if let d = options.xDomain { xDomain = d }
        let yDomain = options.yDomain ?? domain(ys, includeZero: true)
        let scales = Scales(
            plot: plot, xDomain: xDomain, yDomain: yDomain, categories: categories,
            startPadding: options.xRange.startPadding, endPadding: options.xRange.endPadding)

        var paths: [String] = []
        var labels: [Label] = []
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let gridColor = scheme == .dark ? "#3a3a3c" : "#e5e5ea"

        // Y ticks: grid lines across the plot, labels beside it.
        let yTicks = ticks(for: yDomain, spec: options.yAxis, count: 4)
        if yVisible {
            for tick in yTicks {
                let y = scales.y(tick.value)
                paths.append(line(from: (plot.minX, y), to: (plot.maxX, y), stroke: gridColor, width: 1, dash: []))
                let text = format(tick, spec: options.yAxis, index: 0, count: yTicks.count, isDate: false)
                labels.append(Label(text: text, x: yLeading ? plot.minX - 17 : plot.maxX + 17, y: y))
            }
        }
        // X ticks: labels under the plot; explicit values win, dates get a
        // date format, categories their names.
        if xVisible {
            if !categories.isEmpty {
                for (index, category) in categories.enumerated() {
                    labels.append(Label(text: category, x: scales.x(PlotPoint(value: 0, category: category)), y: plot.maxY + 10))
                    _ = index
                }
            } else {
                let isDate = xDomain.lowerBound > 1_000_000_000 && xDomain.upperBound < 10_000_000_000
                let xTicks = options.xAxis.values.map { $0.filter { $0.category == nil } }
                    ?? strideTicks(for: xDomain, spec: options.xAxis, isDate: isDate)
                    ?? ticks(for: xDomain, spec: options.xAxis, count: 3)
                for (index, tick) in xTicks.enumerated() {
                    let text = format(tick, spec: options.xAxis, index: index, count: xTicks.count, isDate: isDate)
                    labels.append(Label(text: text, x: scales.x(tick), y: plot.maxY + 10))
                }
            }
            if !(yVisible && yTicks.contains { abs(scales.y($0.value) - plot.maxY) < 0.5 }) {
                paths.append(line(from: (plot.minX, plot.maxY), to: (plot.maxX, plot.maxY), stroke: gridColor, width: 1, dash: []))
            }
        }

        // Marks. Lines and areas group by series, in the order their first
        // point appeared; everything else draws as it came.
        var seriesOrder: [String] = []
        var seriesIndex: [String: Int] = [:]
        func color(of mark: PreviewMark) -> String {
            let base: Color
            if let c = mark.color {
                base = c
            } else if let s = mark.series {
                if let mapped = options.seriesColors[s] {
                    base = mapped
                } else {
                    if seriesIndex[s] == nil {
                        seriesIndex[s] = seriesOrder.count
                        seriesOrder.append(s)
                    }
                    base = palette[seriesIndex[s]! % palette.count]
                }
            } else {
                base = .accentColor
            }
            return hex(base.resolve(in: environment), opacity: mark.opacity)
        }
        func opacityAttr(of mark: PreviewMark) -> String {
            let resolved = (mark.color ?? .accentColor).resolve(in: environment)
            let alpha = Double(resolved.opacity) * mark.opacity
            return alpha < 0.999 ? String(format: " opacity=\"%.3f\"", alpha) : ""
        }

        var lineGroups: [(key: String, marks: [PreviewMark])] = []
        var areaGroups: [(key: String, marks: [PreviewMark])] = []
        func append(_ mark: PreviewMark, to groups: inout [(key: String, marks: [PreviewMark])]) {
            let key = mark.series ?? ""
            if let i = groups.firstIndex(where: { $0.key == key }) {
                groups[i].marks.append(mark)
            } else {
                groups.append((key, [mark]))
            }
        }
        for mark in marks {
            switch mark.kind {
            case .line: append(mark, to: &lineGroups)
            case .area: append(mark, to: &areaGroups)
            default: break
            }
        }
        let baseline = scales.y(max(yDomain.lowerBound, min(0, yDomain.upperBound)))
        for group in areaGroups {
            let pts = group.marks.compactMap { m -> (Double, Double)? in
                guard let x = m.x, let top = m.y ?? m.yEnd else { return nil }
                return (scales.x(x), scales.y(top.value))
            }
            guard pts.count > 1, let first = group.marks.first else { continue }
            let bottoms = group.marks.map { m in m.yStart.map { scales.y($0.value) } ?? baseline }
            var d = polyline(pts, smooth: first.smooth)
            for (x, y) in zip(pts.map(\.0), bottoms).reversed().map({ ($0.0, $0.1) }) {
                d += String(format: " L %.2f %.2f", x, y)
            }
            d += " Z"
            paths.append("<path d=\"\(d)\" fill=\"\(color(of: first))\"\(opacityAttr(of: first))/>")
        }
        for mark in marks where mark.kind == .bar || mark.kind == .rectangle {
            let rect: CGRect
            if mark.kind == .bar, let x = mark.x {
                let cx = scales.x(x)
                let width = x.category != nil ? scales.bandWidth() * 0.6 : max(min(plot.width / Double(max(marks.count, 1)) * 0.6, 40), 2)
                let top = scales.y((mark.yEnd ?? mark.y)?.value ?? 0)
                let bottom = mark.yStart.map { scales.y($0.value) } ?? baseline
                rect = CGRect(x: cx - width / 2, y: min(top, bottom), width: width, height: abs(bottom - top))
            } else if let x0 = mark.x, let x1 = mark.xEnd {
                let left = scales.x(x0), right = scales.x(x1)
                let top = mark.yEnd.map { scales.y($0.value) } ?? plot.minY
                let bottom = mark.yStart.map { scales.y($0.value) } ?? (mark.y.map { scales.y($0.value) } ?? plot.maxY)
                rect = CGRect(x: min(left, right), y: min(top, bottom), width: abs(right - left), height: abs(bottom - top))
            } else {
                continue
            }
            paths.append(rectPath(rect, radius: mark.cornerRadius, fill: color(of: mark), extra: opacityAttr(of: mark)))
        }
        for group in lineGroups {
            let pts = group.marks.compactMap { m -> (Double, Double)? in
                guard let x = m.x, let y = m.y else { return nil }
                return (scales.x(x), scales.y(y.value))
            }
            guard let first = group.marks.first else { continue }
            if pts.count > 1 {
                let d = polyline(pts, smooth: first.smooth)
                paths.append("<path d=\"\(d)\" fill=\"none\" stroke=\"\(color(of: first))\" stroke-width=\"\(trim(first.lineWidth))\" stroke-linecap=\"round\" stroke-linejoin=\"round\"\(opacityAttr(of: first))/>")
            }
            if first.symbol {
                for (x, y) in pts {
                    paths.append(circlePath(x, y, radius: 3.5, fill: color(of: first), extra: opacityAttr(of: first)))
                }
            }
        }
        for mark in marks where mark.kind == .point {
            guard let x = mark.x, let y = mark.y else { continue }
            paths.append(circlePath(scales.x(x), scales.y(y.value), radius: 4, fill: color(of: mark), extra: opacityAttr(of: mark)))
        }
        for mark in marks where mark.kind == .rule {
            let stroke = color(of: mark)
            if let x = mark.x, mark.y == nil {
                let px = scales.x(x)
                let top = mark.yEnd.map { scales.y($0.value) } ?? plot.minY
                let bottom = mark.yStart.map { scales.y($0.value) } ?? plot.maxY
                paths.append(line(from: (px, top), to: (px, bottom), stroke: stroke, width: mark.lineWidth, dash: mark.dash, extra: opacityAttr(of: mark)))
            } else if let y = mark.y {
                let py = scales.y(y.value)
                let left = mark.x.map { scales.x($0) } ?? plot.minX
                let right = mark.xEnd.map { scales.x($0) } ?? plot.maxX
                paths.append(line(from: (left, py), to: (right, py), stroke: stroke, width: mark.lineWidth, dash: mark.dash, extra: opacityAttr(of: mark)))
            }
        }

        // The SVG is drawn in the plot's own coordinates, so translate.
        let translated = paths.joined(separator: "\n")
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"\(trim(plot.minX)) \(trim(plot.minY)) \(trim(plot.width)) \(trim(plot.height))\">\n\(translated)\n</svg>"
        return Layout(scales: scales, svg: svg, labels: labels)
    }

    // MARK: Domains and ticks

    static func domain(_ values: [Double], includeZero: Bool) -> ClosedRange<Double> {
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        var lower = includeZero ? min(0, low) : low
        var upper = includeZero ? max(0, high) : high
        if upper - lower < 1e-9 {
            // A single value: a domain around it, so the mark lands mid plot.
            if includeZero, upper > 0 { lower = 0 } else { lower -= 1 }
            upper += 1
        }
        if includeZero {
            let step = niceStep((upper - lower) / 4)
            upper = (upper / step).rounded(.up) * step
            lower = (lower / step).rounded(.down) * step
        }
        return lower...upper
    }

    static func niceStep(_ raw: Double) -> Double {
        guard raw > 0, raw.isFinite else { return 1 }
        let magnitude = pow(10, floor(log10(raw)))
        let fraction = raw / magnitude
        let nice: Double = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 5 ? 5 : 10
        return nice * magnitude
    }

    static func ticks(for domain: ClosedRange<Double>, spec: AxisSpec, count: Int) -> [PlotPoint] {
        if let values = spec.values {
            return values.filter { $0.category == nil }
        }
        let span = domain.upperBound - domain.lowerBound
        guard span > 0 else { return [PlotPoint(value: domain.lowerBound, category: nil)] }
        let step = niceStep(span / Double(count))
        var out: [PlotPoint] = []
        var v = (domain.lowerBound / step).rounded(.up) * step
        while v <= domain.upperBound + step * 1e-6 {
            out.append(PlotPoint(value: v, category: nil))
            v += step
        }
        return out
    }

    static func strideTicks(for domain: ClosedRange<Double>, spec: AxisSpec, isDate: Bool) -> [PlotPoint]? {
        guard isDate, let stride = spec.stride else { return nil }
        let calendar = Calendar.current
        var out: [PlotPoint] = []
        var date = Date(timeIntervalSince1970: domain.lowerBound)
        let end = Date(timeIntervalSince1970: domain.upperBound)
        var guardCount = 0
        while date <= end, guardCount < 60 {
            out.append(PlotPoint(value: date.timeIntervalSince1970, category: nil))
            guard let next = calendar.date(byAdding: stride.component, value: stride.count, to: date) else { break }
            date = next
            guardCount += 1
        }
        return out
    }

    static func format(_ point: PlotPoint, spec: AxisSpec, index: Int, count: Int, isDate: Bool) -> String {
        if let label = spec.label {
            if let text = label.text {
                return text(AxisValue(point: point, index: index, count: count))
            }
            if let f = label.dateFormat {
                return f.format(Date(timeIntervalSince1970: point.value))
            }
            if let f = label.numberFormat {
                return f.format(point.value)
            }
        }
        if let category = point.category { return category }
        if isDate {
            return Date(timeIntervalSince1970: point.value).formatted(.dateTime.month(.abbreviated).day())
        }
        return number(point.value)
    }

    static func number(_ value: Double) -> String {
        if abs(value) >= 1_000_000 { return trim(value / 1_000_000) + "M" }
        if abs(value) >= 10_000 { return trim(value / 1_000) + "K" }
        return trim(value)
    }

    // MARK: SVG pieces

    static func trim(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        var s = String(format: "%.2f", rounded)
        while s.hasSuffix("0") { s.removeLast() }
        return s
    }

    static func hex(_ c: Color.Resolved, opacity: Double) -> String {
        let r = Int((max(0, min(1, Double(c.red))) * 255).rounded())
        let g = Int((max(0, min(1, Double(c.green))) * 255).rounded())
        let b = Int((max(0, min(1, Double(c.blue))) * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }

    static func polyline(_ pts: [(Double, Double)], smooth: Bool) -> String {
        guard let first = pts.first else { return "" }
        var d = String(format: "M %.2f %.2f", first.0, first.1)
        if !smooth || pts.count < 3 {
            for p in pts.dropFirst() { d += String(format: " L %.2f %.2f", p.0, p.1) }
            return d
        }
        // Catmull-Rom through the points, as cubic Béziers.
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, pts.count - 1)]
            let c1 = (p1.0 + (p2.0 - p0.0) / 6, p1.1 + (p2.1 - p0.1) / 6)
            let c2 = (p2.0 - (p3.0 - p1.0) / 6, p2.1 - (p3.1 - p1.1) / 6)
            d += String(format: " C %.2f %.2f %.2f %.2f %.2f %.2f", c1.0, c1.1, c2.0, c2.1, p2.0, p2.1)
        }
        return d
    }

    /// A stroked line; a dash pattern is laid out by hand because the host
    /// painter has no stroke-dasharray.
    static func line(from a: (Double, Double), to b: (Double, Double), stroke: String, width: Double, dash: [Double], extra: String = "") -> String {
        var d = ""
        if dash.count >= 2, dash[0] > 0 {
            let length = ((b.0 - a.0) * (b.0 - a.0) + (b.1 - a.1) * (b.1 - a.1)).squareRoot()
            guard length > 0 else { return "" }
            let ux = (b.0 - a.0) / length, uy = (b.1 - a.1) / length
            var t = 0.0
            var i = 0
            while t < length {
                let seg = min(dash[i % dash.count], length - t)
                if i % 2 == 0 {
                    d += String(format: " M %.2f %.2f L %.2f %.2f", a.0 + ux * t, a.1 + uy * t, a.0 + ux * (t + seg), a.1 + uy * (t + seg))
                }
                t += seg
                i += 1
            }
        } else {
            d = String(format: "M %.2f %.2f L %.2f %.2f", a.0, a.1, b.0, b.1)
        }
        return "<path d=\"\(d.trimmingCharacters(in: .whitespaces))\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(trim(width))\"\(extra)/>"
    }

    static func rectPath(_ r: CGRect, radius: Double, fill: String, extra: String) -> String {
        let rad = min(radius, r.width / 2, r.height / 2)
        let d: String
        if rad > 0 {
            d = String(format: "M %.2f %.2f L %.2f %.2f A %.2f %.2f 0 0 1 %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f A %.2f %.2f 0 0 1 %.2f %.2f Z",
                       r.minX, r.maxY, r.minX, r.minY + rad, rad, rad, r.minX + rad, r.minY,
                       r.maxX - rad, r.minY, rad, rad, r.maxX, r.minY + rad, r.maxX, r.maxY)
        } else {
            d = String(format: "M %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f Z", r.minX, r.minY, r.maxX, r.minY, r.maxX, r.maxY, r.minX, r.maxY)
        }
        return "<path d=\"\(d)\" fill=\"\(fill)\"\(extra)/>"
    }

    static func circlePath(_ cx: Double, _ cy: Double, radius: Double, fill: String, extra: String) -> String {
        let d = String(format: "M %.2f %.2f A %.2f %.2f 0 1 0 %.2f %.2f A %.2f %.2f 0 1 0 %.2f %.2f Z",
                       cx - radius, cy, radius, radius, cx + radius, cy, radius, radius, cx - radius, cy)
        return "<path d=\"\(d)\" fill=\"\(fill)\"\(extra)/>"
    }

    /// The words of a label view, for an axis label built from `Text`.
    static func plainText<V: View>(of view: V) -> String {
        "\(view)".contains("Text") ? String(describing: view).components(separatedBy: "\"").dropFirst().first ?? "" : ""
    }
}
