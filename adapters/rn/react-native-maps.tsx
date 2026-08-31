// Preview adapter for react-native-maps.
// Covers: MapView and Marker as a placeholder that renders the region and its
// markers as text, which is enough to build the surrounding screen and state.
// Drop into .mobai/preview/rn/mocks/.
import React from 'react';
import { View, Text } from 'react-native';

type Region = { latitude: number; longitude: number };

export function Marker(props: { coordinate: Region; title?: string }) {
  return (
    <Text accessibilityLabel={props.title ?? 'marker'}>
      {'● '}{props.title ?? `${props.coordinate.latitude.toFixed(3)}, ${props.coordinate.longitude.toFixed(3)}`}
    </Text>
  );
}

export default function MapView(props: {
  region?: Region;
  initialRegion?: Region;
  style?: object;
  children?: React.ReactNode;
}) {
  const region = props.region ?? props.initialRegion;
  const label = region
    ? `map at ${region.latitude.toFixed(3)}, ${region.longitude.toFixed(3)}`
    : 'map';
  return (
    <View style={[{ minHeight: 160, backgroundColor: '#d2ddd0', padding: 12 }, props.style]} accessibilityLabel={label}>
      <Text>{label}</Text>
      {props.children}
    </View>
  );
}
