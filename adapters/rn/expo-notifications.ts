// Preview adapter: expo-notifications on the permissions and notifications
// primitives: permissions, tokens, listeners, badges, scheduling as no-ops.
import { notifications, permissions } from 'mobai-preview';

const status = () => {
  const s = permissions.status('notifications');
  return { status: s === 'prompt' ? 'undetermined' : s, granted: s === 'granted', canAskAgain: s !== 'denied', expires: 'never' };
};

export const AndroidImportance = { MAX: 5, HIGH: 4, DEFAULT: 3, LOW: 2, MIN: 1, NONE: 0, UNSPECIFIED: -1000 };
export function setNotificationHandler() {}
export async function setNotificationChannelAsync() {
  return null;
}
export async function getPermissionsAsync() {
  return status();
}
export async function requestPermissionsAsync() {
  await permissions.request('notifications');
  return status();
}
export async function getExpoPushTokenAsync() {
  return { type: 'expo', data: 'ExponentPushToken[preview-token]' };
}
export async function getDevicePushTokenAsync() {
  return { type: 'ios', data: 'preview-device-token' };
}
export function addNotificationReceivedListener(listener: (n: unknown) => void) {
  const pending = notifications.next();
  if (pending) setTimeout(() => listener({ request: { content: pending } }), 0);
  return { remove: () => {} };
}
export function addNotificationResponseReceivedListener() {
  return { remove: () => {} };
}
export function removeNotificationSubscription() {}
export async function getLastNotificationResponseAsync() {
  return null;
}
export async function setBadgeCountAsync() {
  return true;
}
export async function getBadgeCountAsync() {
  return 0;
}
export async function scheduleNotificationAsync() {
  return 'preview-notification';
}
export async function dismissAllNotificationsAsync() {}
