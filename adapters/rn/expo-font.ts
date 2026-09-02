// Preview adapter: expo-font. The real package reaches @react-native/assets-registry
// (Flow source in RN 0.76) which the preview bundler cannot parse. Fonts are
// reported loaded immediately; the vector-icons adapter injects its own @font-face.
export function useFonts(_map?: unknown): [boolean, Error | null] {
  return [true, null];
}
export async function loadAsync() {}
export function isLoaded() {
  return true;
}
export function isLoading() {
  return false;
}
export async function unloadAsync() {}
export function getLoadedFonts(): string[] {
  return [];
}
export const FontDisplay = { AUTO: 'auto', SWAP: 'swap', BLOCK: 'block', FALLBACK: 'fallback', OPTIONAL: 'optional' };
