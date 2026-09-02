// Preview adapter: expo-image on react-native-web's Image. The real package's
// web build imports the Flow-typed @react-native/assets-registry (RN 0.76),
// which the preview bundler cannot parse. Covers the Image surface an app
// commonly uses: source objects/strings/numbers, contentFit, blurhash placeholder
// (rendered as a flat grey background), transition/recyclingKey ignored.
import React from 'react';
import { Image as RNImage, View, type ImageProps as RNImageProps, type ImageStyle } from 'react-native';

type Source = string | number | { uri?: string; width?: number; height?: number; blurhash?: string } | Array<unknown> | null | undefined;
type Props = Omit<RNImageProps, 'source' | 'resizeMode'> & {
  source?: Source;
  contentFit?: 'cover' | 'contain' | 'fill' | 'none' | 'scale-down';
  contentPosition?: unknown;
  placeholder?: Source;
  placeholderContentFit?: string;
  transition?: unknown;
  recyclingKey?: string;
  cachePolicy?: string;
  priority?: string;
  allowDownscaling?: boolean;
  autoplay?: boolean;
  style?: ImageStyle | ImageStyle[];
};

const fitToMode = { cover: 'cover', contain: 'contain', fill: 'stretch', none: 'center', 'scale-down': 'contain' } as const;

function normalize(source: Source): RNImageProps['source'] | undefined {
  if (source == null) return undefined;
  if (typeof source === 'string') return { uri: source };
  if (typeof source === 'number') return source;
  if (Array.isArray(source)) return normalize(source[0] as Source);
  if (typeof source === 'object' && 'uri' in source && source.uri) return { uri: source.uri, width: source.width, height: source.height };
  return undefined;
}

export const Image = React.forwardRef<RNImage, Props>(function Image(
  { source, contentFit = 'cover', placeholder, style, contentPosition, placeholderContentFit, transition, recyclingKey, cachePolicy, priority, allowDownscaling, autoplay, ...rest },
  ref,
) {
  const src = normalize(source);
  if (!src) {
    return <View accessibilityLabel={rest.accessibilityLabel ?? 'image placeholder'} style={[{ backgroundColor: '#d9d9d9' }, style]} />;
  }
  return <RNImage ref={ref} {...rest} source={src} resizeMode={fitToMode[contentFit] ?? 'cover'} style={[{ backgroundColor: '#e5e5e5' }, style]} />;
}) as unknown as React.ForwardRefExoticComponent<Props> & {
  prefetch: (urls: string | string[]) => Promise<boolean>;
  clearMemoryCache: () => Promise<boolean>;
  clearDiskCache: () => Promise<boolean>;
  getCachePathAsync: (key: string) => Promise<string | null>;
};
Image.prefetch = async () => true;
Image.clearMemoryCache = async () => true;
Image.clearDiskCache = async () => true;
Image.getCachePathAsync = async () => null;

export function ImageBackground({ children, style, ...props }: Props & { children?: React.ReactNode; imageStyle?: ImageStyle }) {
  return (
    <View style={style}>
      <Image {...props} style={[{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }, props.imageStyle]} />
      {children}
    </View>
  );
}
export default Image;
