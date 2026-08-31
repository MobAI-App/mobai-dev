// Preview adapter for Apple's Charts framework. Chart marks keep their public
// construction and modifier shape; the chart itself renders a stable empty
// plot so the application's surrounding layout remains testable.

import Foundation
import SwiftUI

public protocol Plottable {}
public protocol ChartContent {}
public protocol AxisContent {}
public protocol AxisMark {}

extension Date: Plottable {}
extension Double: Plottable {}
extension Int: Plottable {}
extension String: Plottable {}
extension Never: ChartContent, AxisContent, AxisMark {}
extension ForEach: ChartContent {}

public struct PlottableValue<Value: Plottable>: Hashable where Value: Hashable {
    public let value: Value

    private init(_ value: Value) {
        self.value = value
    }

    public static func value(_ label: LocalizedStringKey, _ value: Value) -> Self {
        Self(value)
    }

    public static func value(
        _ label: LocalizedStringKey,
        _ value: Date,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self where Value == Date {
        Self(value)
    }
}

@resultBuilder
public enum ChartContentBuilder {
    public static func buildBlock<Content: ChartContent>(_ content: Content) -> Content { content }
    public static func buildBlock<A: ChartContent, B: ChartContent>(
        _ first: A, _ second: B
    ) -> TupleChartContent<A, B> {
        TupleChartContent()
    }
    public static func buildOptional<Content: ChartContent>(
        _ content: Content?
    ) -> OptionalChartContent<Content> {
        OptionalChartContent()
    }
    public static func buildEither<TrueContent: ChartContent, FalseContent: ChartContent>(
        first: TrueContent
    ) -> ConditionalChartContent<TrueContent, FalseContent> {
        ConditionalChartContent()
    }
    public static func buildEither<TrueContent: ChartContent, FalseContent: ChartContent>(
        second: FalseContent
    ) -> ConditionalChartContent<TrueContent, FalseContent> {
        ConditionalChartContent()
    }
}

@resultBuilder
public enum AxisContentBuilder {
    public static func buildBlock<Content: AxisContent>(_ content: Content) -> Content { content }
}

public struct TupleChartContent<A: ChartContent, B: ChartContent>: ChartContent {
    public init() {}
}

public struct OptionalChartContent<Content: ChartContent>: ChartContent {
    public init() {}
}

public struct ConditionalChartContent<TrueContent: ChartContent, FalseContent: ChartContent>: ChartContent {
    public init() {}
}

public struct Chart<Content: ChartContent>: View {
    public init(@ChartContentBuilder content: () -> Content) {}

    public init<Data: RandomAccessCollection>(
        _ data: Data,
        @ChartContentBuilder content: (Data.Element) -> Content
    ) {}

    public var body: some View {
        Color.clear.accessibilityLabel("Chart")
    }
}

public struct InterpolationMethod: Hashable, Sendable {
    public init() {}
    public static let catmullRom = InterpolationMethod()
}

public struct BasicChartSymbolShape: Hashable, Sendable {
    public init() {}
    public static let circle = BasicChartSymbolShape()
}

public extension ChartContent {
    func foregroundStyle<S>(_ style: S) -> Self { self }
    func interpolationMethod(_ method: InterpolationMethod) -> Self { self }
    func lineStyle(_ style: StrokeStyle) -> Self { self }
    func symbol(_ symbol: BasicChartSymbolShape) -> Self { self }
}

public struct AreaMark: ChartContent {
    public init<X: Plottable & Hashable, Y: Plottable & Hashable>(
        x: PlottableValue<X>, y: PlottableValue<Y>
    ) {}
}

public struct LineMark: ChartContent {
    public init<X: Plottable & Hashable, Y: Plottable & Hashable>(
        x: PlottableValue<X>, y: PlottableValue<Y>
    ) {}
}

public struct RuleMark: ChartContent {
    public init<X: Plottable & Hashable>(x: PlottableValue<X>) {}
}

public struct RectangleMark: ChartContent {
    public init<X: Plottable & Hashable, Y: Plottable & Hashable>(
        xStart: PlottableValue<X>,
        xEnd: PlottableValue<X>,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>
    ) {}
}

public struct AxisMarkPosition: Hashable, Sendable {
    public init() {}
    public static let automatic = AxisMarkPosition()
    public static let leading = AxisMarkPosition()
    public static let trailing = AxisMarkPosition()
}

public struct AxisValue {
    public init() {}
}

public struct AxisMarks<Content: AxisMark>: AxisContent {
    public init(position: AxisMarkPosition = .automatic) where Content == Never {}

    public init<Value>(
        position: AxisMarkPosition = .automatic,
        values: [Value],
        content: (AxisValue) -> Content
    ) {}
}

public struct AxisValueLabel<Content: View>: AxisMark {
    public init(
        format: Date.FormatStyle,
        centered: Bool? = nil
    ) where Content == Text {}
}

public struct PlotDimensionScaleRange: Hashable, Sendable {
    public init() {}
    public static func plotDimension(
        padding: CGFloat = 0
    ) -> PlotDimensionScaleRange { PlotDimensionScaleRange() }
    public static func plotDimension(
        startPadding: CGFloat = 0,
        endPadding: CGFloat = 0
    ) -> PlotDimensionScaleRange { PlotDimensionScaleRange() }
}

public struct ChartProxy: Hashable, Sendable {
    public init() {}
    public func position<P: Plottable>(forX value: P) -> CGFloat? { nil }
    public func position<P: Plottable>(forY value: P) -> CGFloat? { nil }
}

public struct AnnotationPosition: Hashable, Sendable {
    public init() {}
    public static let automatic = AnnotationPosition()
}

public extension View {
    func chartLegend(_ visibility: Visibility) -> some View { self }
    func chartXAxis(_ visibility: Visibility) -> some View { self }
    func chartYAxis(_ visibility: Visibility) -> some View { self }
    func chartXAxis<Content: AxisContent>(@AxisContentBuilder content: () -> Content) -> some View { self }
    func chartYAxis<Content: AxisContent>(@AxisContentBuilder content: () -> Content) -> some View { self }
    func chartXSelection<P: Plottable>(value: Binding<P?>) -> some View { self }
    func chartXScale<Domain>(domain: Domain) -> some View { self }
    func chartXScale(range: PlotDimensionScaleRange) -> some View { self }
    func chartYScale<Domain>(domain: Domain) -> some View { self }
    func chartOverlay<Content: View>(@ViewBuilder content: (ChartProxy) -> Content) -> some View {
        overlay { content(ChartProxy()) }
    }
}
