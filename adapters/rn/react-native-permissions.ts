// Preview adapter: react-native-permissions on the permissions primitive.
import { permissions } from 'mobai-preview';

export const RESULTS = { UNAVAILABLE: 'unavailable', BLOCKED: 'blocked', DENIED: 'denied', GRANTED: 'granted', LIMITED: 'limited' } as const;
const names = ['CAMERA', 'MICROPHONE', 'PHOTO_LIBRARY', 'PHOTO_LIBRARY_ADD_ONLY', 'LOCATION_WHEN_IN_USE', 'LOCATION_ALWAYS', 'NOTIFICATIONS', 'CONTACTS', 'MEDIA_LIBRARY', 'RECORD_AUDIO', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE', 'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'POST_NOTIFICATIONS', 'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION'];
const set = (prefix: string) => Object.fromEntries(names.map((n) => [n, `${prefix}.${n}`]));
export const PERMISSIONS = { IOS: set('ios.permission'), ANDROID: set('android.permission'), WINDOWS: set('windows.permission') };

function capability(permission: string): string {
  const key = permission.split('.').pop() ?? '';
  if (/CAMERA/.test(key)) return 'camera';
  if (/MICROPHONE|RECORD_AUDIO/.test(key)) return 'microphone';
  if (/PHOTO|MEDIA|STORAGE/.test(key)) return 'photos';
  if (/LOCATION/.test(key)) return 'location';
  if (/NOTIFICATION/.test(key)) return 'notifications';
  return key.toLowerCase();
}
const toResult = (s: string) => (s === 'granted' ? RESULTS.GRANTED : s === 'denied' ? RESULTS.BLOCKED : RESULTS.DENIED);
export async function check(permission: string) {
  return toResult(permissions.status(capability(permission)));
}
export async function request(permission: string) {
  return toResult(await permissions.request(capability(permission)));
}
export async function checkMultiple(list: string[]) {
  return Object.fromEntries(await Promise.all(list.map(async (p) => [p, await check(p)])));
}
export async function requestMultiple(list: string[]) {
  return Object.fromEntries(await Promise.all(list.map(async (p) => [p, await request(p)])));
}
export async function checkNotifications() {
  return { status: toResult(permissions.status('notifications')), settings: {} };
}
export async function requestNotifications() {
  return { status: toResult(await permissions.request('notifications')), settings: {} };
}
export async function openSettings() {}
export default { RESULTS, PERMISSIONS, check, request, checkMultiple, requestMultiple, checkNotifications, requestNotifications, openSettings };
