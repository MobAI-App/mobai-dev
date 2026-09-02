// Preview adapter: @react-native-firebase/messaging (modular API). No FCM in a
// preview: token is a constant, no initial notification, listeners never fire.
import { notifications, permissions } from 'mobai-preview';

const instance = { app: { name: '[DEFAULT]' } };
export function getMessaging() {
  return instance;
}
export async function getToken() {
  return 'preview-fcm-token';
}
export async function deleteToken() {}
export async function getInitialNotification() {
  const next = notifications.next();
  return next ? { notification: { title: next.title, body: next.body }, data: next.data ?? {} } : null;
}
export function onNotificationOpenedApp() {
  return () => {};
}
export function onMessage() {
  return () => {};
}
export function onTokenRefresh() {
  return () => {};
}
export function setBackgroundMessageHandler() {}
export async function requestPermission() {
  return (await permissions.request('notifications')) === 'granted' ? 1 : 0;
}
export async function hasPermission() {
  return permissions.status('notifications') === 'granted' ? 1 : 0;
}
export async function registerDeviceForRemoteMessages() {}
export async function isDeviceRegisteredForRemoteMessages() {
  return true;
}
export const AuthorizationStatus = { NOT_DETERMINED: -1, DENIED: 0, AUTHORIZED: 1, PROVISIONAL: 2 };
export default function messaging() {
  return { ...instance, getToken, getInitialNotification, onNotificationOpenedApp, onMessage, setBackgroundMessageHandler, requestPermission, hasPermission, deleteToken };
}
