// Preview adapter: react-native-keyboard-controller. No native keyboard in a
// preview: providers and areas render their children, aware views are plain
// ScrollViews, hooks report a closed keyboard.
import React from 'react';
import { ScrollView, View, type ScrollViewProps, type ViewProps } from 'react-native';
import { useSharedValue } from 'react-native-reanimated';

export function KeyboardProvider({ children }: { children?: React.ReactNode; statusBarTranslucent?: boolean; navigationBarTranslucent?: boolean }) {
  return <>{children}</>;
}
export const KeyboardAwareScrollView = React.forwardRef<ScrollView, ScrollViewProps & { bottomOffset?: number; extraKeyboardSpace?: number; disableScrollOnKeyboardHide?: boolean }>(
  function KeyboardAwareScrollView({ bottomOffset, extraKeyboardSpace, disableScrollOnKeyboardHide, ...props }, ref) {
    return <ScrollView ref={ref} {...props} />;
  },
);
export function KeyboardGestureArea({ children, style, ...rest }: ViewProps & { interpolator?: string; offset?: number; textInputNativeID?: string; showOnSwipeUp?: boolean }) {
  return <View style={style}>{children}</View>;
}
export function KeyboardStickyView({ children, style, offset }: ViewProps & { offset?: { closed?: number; opened?: number } }) {
  return <View style={style}>{children}</View>;
}
export function KeyboardAvoidingView({ children, style }: ViewProps & { behavior?: string; keyboardVerticalOffset?: number }) {
  return <View style={style}>{children}</View>;
}
export function KeyboardToolbar() {
  return null;
}
export function useKeyboardHandler() {}
export function useKeyboardAnimation() {
  return { height: useSharedValue(0), progress: useSharedValue(0) };
}
export function useReanimatedKeyboardAnimation() {
  return { height: useSharedValue(0), progress: useSharedValue(0) };
}
export function useKeyboardState() {
  return { isVisible: false, height: 0 };
}
export function useKeyboardController() {
  return { setEnabled() {}, enabled: true };
}
export function useResizeMode() {}
export function useGradualAnimation() {
  return { height: useSharedValue(0) };
}
export const KeyboardController = { setInputMode() {}, setDefaultMode() {}, dismiss: async () => {}, setFocusTo() {}, isVisible: () => false, state: () => null };
export const KeyboardEvents = { addListener: () => ({ remove() {} }) };
export const AndroidSoftInputModes = { SOFT_INPUT_ADJUST_RESIZE: 16, SOFT_INPUT_ADJUST_PAN: 32, SOFT_INPUT_ADJUST_NOTHING: 48 };
export const FocusedInputEvents = { addListener: () => ({ remove() {} }) };
export function useFocusedInputHandler() {}
export function useWindowDimensions() {
  return { width: 393, height: 852 };
}
