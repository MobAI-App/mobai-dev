// Preview adapter: @react-native-firebase/app.
export function getApp() {
  return { name: '[DEFAULT]', options: {} };
}
export function getApps() {
  return [getApp()];
}
export async function initializeApp() {
  return getApp();
}
export default { app: getApp, apps: [getApp()] };
