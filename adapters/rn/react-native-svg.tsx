// Preview adapter: react-native-svg rendered as real DOM <svg> elements through
// react-native-web's createElement. The real package's web build imports the
// Flow-typed @react-native/assets-registry, which the preview bundler cannot
// parse. Covers the primitive elements; props pass through as SVG attributes.
import React from 'react';
import { unstable_createElement as createElement } from 'react-native-web';

type AnyProps = Record<string, unknown> & { children?: React.ReactNode; style?: unknown };

function flatten(style: unknown): Record<string, unknown> {
  if (!style) return {};
  if (Array.isArray(style)) return Object.assign({}, ...style.map(flatten));
  return style as Record<string, unknown>;
}

function svgElement(tag: string) {
  const Element = React.forwardRef<unknown, AnyProps>(function SvgElement({ children, style, ...props }, ref) {
    return createElement(tag, { ...props, ref, style: flatten(style) }, children);
  });
  Element.displayName = tag;
  return Element;
}

export const Svg = React.forwardRef<unknown, AnyProps>(function Svg({ children, style, width, height, viewBox, ...props }, ref) {
  const flat = flatten(style);
  const w = width ?? flat.width;
  const h = height ?? flat.height;
  return createElement(
    'svg',
    { ...props, ref, width: w, height: h, viewBox, style: { ...flat, width: w, height: h, display: 'flex' } },
    children,
  );
});

export const Path = svgElement('path');
export const Circle = svgElement('circle');
export const Ellipse = svgElement('ellipse');
export const Rect = svgElement('rect');
export const Line = svgElement('line');
export const Polygon = svgElement('polygon');
export const Polyline = svgElement('polyline');
export const G = svgElement('g');
export const Defs = svgElement('defs');
export const Stop = svgElement('stop');
export const LinearGradient = svgElement('linearGradient');
export const RadialGradient = svgElement('radialGradient');
export const ClipPath = svgElement('clipPath');
export const Mask = svgElement('mask');
export const Use = svgElement('use');
export const Symbol = svgElement('symbol');
export const Text = svgElement('text');
export const TSpan = svgElement('tspan');
export const Pattern = svgElement('pattern');
export const Image = svgElement('image');
export const ForeignObject = svgElement('foreignObject');
export const Marker = svgElement('marker');

export function SvgXml({ xml, width, height, style }: { xml: string | null; width?: number; height?: number; style?: unknown }) {
  return createElement('div', { style: { ...flatten(style), width, height }, dangerouslySetInnerHTML: { __html: xml ?? '' } });
}
export const SvgUri = () => null;
export const SvgCss = SvgXml;
export const SvgCssUri = SvgUri;
export const WithLocalSvg = () => null;
export default Svg;
