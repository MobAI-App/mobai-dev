// Preview adapter: @notifee/react-native. Local notifications are no-ops.
import { permissions } from 'mobai-preview';
export const AuthorizationStatus = { NOT_DETERMINED: -1, DENIED: 0, AUTHORIZED: 1, PROVISIONAL: 2 };
export const EventType = { DISMISSED: 0, PRESS: 1, ACTION_PRESS: 2, DELIVERED: 3, APP_BLOCKED: 4, CHANNEL_BLOCKED: 5, CHANNEL_GROUP_BLOCKED: 6, TRIGGER_NOTIFICATION_CREATED: 7 };
export const AndroidImportance = { NONE: 0, MIN: 1, LOW: 2, DEFAULT: 3, HIGH: 4 };
const notifee = {
  requestPermission: async () => ({ authorizationStatus: (await permissions.request('notifications')) === 'granted' ? 1 : 0 }),
  getNotificationSettings: async () => ({ authorizationStatus: permissions.status('notifications') === 'granted' ? 1 : 0 }),
  displayNotification: async () => 'preview-notification',
  cancelNotification: async () => {},
  cancelAllNotifications: async () => {},
  cancelDisplayedNotifications: async () => {},
  setBadgeCount: async () => {},
  getBadgeCount: async () => 0,
  incrementBadgeCount: async () => {},
  decrementBadgeCount: async () => {},
  onForegroundEvent: () => () => {},
  onBackgroundEvent: () => {},
  createChannel: async () => 'default',
  getInitialNotification: async () => null,
  getDisplayedNotifications: async () => [],
  setNotificationCategories: async () => {},
};
export default notifee;
