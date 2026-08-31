/**
 * Preview adapter for react-native-image-picker.
 *
 * This is the shape every package mock takes under protocol v0.2: it presents
 * the package's own API and implements it with the MobAI preview primitives, so
 * the app's code is not touched and the scenario decides what comes back.
 */
import { camera, photos, permissions } from 'mobai-preview';

export type MediaType = 'photo' | 'video' | 'mixed';

export interface Asset {
  uri: string;
  fileName: string;
  type: string;
}

export interface Response {
  didCancel: boolean;
  errorCode?: string;
  assets: Asset[];
}

function toResponse(picked: { uri: string; fileName: string } | null): Response {
  if (!picked) {
    return { didCancel: true, assets: [] };
  }
  return { didCancel: false, assets: [{ uri: picked.uri, fileName: picked.fileName, type: 'image/png' }] };
}

export async function launchImageLibrary(): Promise<Response> {
  if ((await permissions.request('photos')) !== 'granted') {
    return { didCancel: false, errorCode: 'permission', assets: [] };
  }
  return toResponse(await photos.pickImage());
}

export async function launchCamera(): Promise<Response> {
  if ((await permissions.request('camera')) !== 'granted') {
    return { didCancel: false, errorCode: 'permission', assets: [] };
  }
  return toResponse(await camera.pickImage());
}
