// Preview adapter: expo-font. The real package reaches @react-native/assets-registry
// (Flow source in RN 0.76) which the preview bundler cannot parse. A font map
// (`useFonts({ Inter: require('./Inter.ttf') })`) is loaded for real: the
// require gives the file's URL in the preview, and each entry becomes an
// @font-face. Fonts are reported loaded at once, as the phone build of an app
// never waits on them either way, so the app mounts on the same schedule.
type Source = string | number | { uri?: string; default?: string } | null | undefined;

const injected = new Set<string>();

function urlOf(source: Source): string | null {
  if (!source) return null;
  if (typeof source === 'string') return source;
  if (typeof source === 'object') return source.uri ?? source.default ?? null;
  return null;
}

function inject(family: string, source: Source): void {
  const url = urlOf(source);
  if (!url || injected.has(family) || typeof document === 'undefined') return;
  injected.add(family);
  const format = /\.otf(\?|$)/i.test(url) ? 'opentype' : /\.woff2(\?|$)/i.test(url) ? 'woff2' : /\.woff(\?|$)/i.test(url) ? 'woff' : 'truetype';
  const style = document.createElement('style');
  style.textContent = `@font-face { font-family: "${family}"; src: url("${url}") format("${format}"); font-display: block; }`;
  document.head.appendChild(style);
}

export async function loadAsync(map: string | Record<string, Source>, source?: Source): Promise<void> {
  if (typeof map === 'string') {
    inject(map, source);
    return;
  }
  for (const [family, entry] of Object.entries(map ?? {})) inject(family, entry);
}

export function useFonts(map?: Record<string, Source>): [boolean, Error | null] {
  for (const [family, entry] of Object.entries(map ?? {})) inject(family, entry);
  return [true, null];
}

export function isLoaded(family?: string): boolean {
  return family ? injected.has(family) : true;
}
export function isLoading(): boolean {
  return false;
}
export async function unloadAsync(): Promise<void> {}
export function getLoadedFonts(): string[] {
  return [...injected];
}
export const FontDisplay = { AUTO: 'auto', SWAP: 'swap', BLOCK: 'block', FALLBACK: 'fallback', OPTIONAL: 'optional' };
