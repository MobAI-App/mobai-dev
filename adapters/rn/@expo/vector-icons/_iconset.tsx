// Shared by the @expo/vector-icons adapters: renders a glyph from the real
// font file, served by the preview's dev server straight out of node_modules,
// with one injected @font-face per family.
import React from 'react';
import { Text, type TextProps } from 'react-native';

const injected = new Set<string>();

function ensureFace(family: string, url: string) {
  if (injected.has(family) || typeof document === 'undefined') return;
  injected.add(family);
  const style = document.createElement('style');
  style.textContent = `@font-face { font-family: "${family}"; src: url("${url}") format("truetype"); font-display: block; }`;
  document.head.appendChild(style);
}

export function createIconSet(glyphMap: Record<string, number | string>, family: string, url: string) {
  ensureFace(family, url);
  type Props = TextProps & { name: string; size?: number; color?: string };
  function Icon({ name, size = 24, color = '#000', style, ...rest }: Props) {
    const code = glyphMap[name];
    const glyph = typeof code === 'number' ? String.fromCodePoint(code) : typeof code === 'string' ? code : '?';
    return (
      <Text
        accessibilityLabel={rest.accessibilityLabel ?? name}
        selectable={false}
        {...rest}
        style={[{ fontFamily: family, fontSize: size, color, lineHeight: size, fontWeight: 'normal', fontStyle: 'normal' }, style]}
      >
        {glyph}
      </Text>
    );
  }
  Icon.font = { [family]: url };
  Icon.glyphMap = glyphMap;
  Icon.getRawGlyphMap = () => glyphMap;
  Icon.getFontFamily = () => family;
  Icon.loadFont = async () => {};
  Icon.hasIcon = (name: string) => name in glyphMap;
  return Icon;
}

export const fontsBase = '/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/';
