// Preview adapter: react-native-device-info with fixed preview values.
export const getSystemName = () => 'iOS';
export const getSystemVersion = () => '18.0';
export const getManufacturer = async () => 'Apple';
export const getModel = () => 'iPhone 16';
export const getApiLevel = async () => -1;
export const getBrand = () => 'Apple';
export const getBuildNumber = () => '1';
export const getVersion = () => '1.0.0';
export const getUniqueId = async () => 'preview-device-id';
export const getDeviceId = () => 'iPhone17,3';
export const getBundleId = () => 'com.example.preview';
export const getApplicationName = () => 'Preview';
export const isTablet = () => false;
export const hasNotch = () => true;
export const getDeviceType = () => 'Handset';
export const getReadableVersion = () => '1.0.0.1';
const DeviceInfo = { getSystemName, getSystemVersion, getManufacturer, getModel, getApiLevel, getBrand, getBuildNumber, getVersion, getUniqueId, getDeviceId, getBundleId, getApplicationName, isTablet, hasNotch, getDeviceType, getReadableVersion };
export default DeviceInfo;
