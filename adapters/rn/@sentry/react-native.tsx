// Preview adapter: @sentry/react-native. No-op reporting; ErrorBoundary passes
// children through, wrap() returns the component as is.
import React from 'react';

export function init() {}
export function wrap<T>(component: T): T {
  return component;
}
export function captureException(e: unknown) {
  console.warn('[sentry preview] captureException', e);
}
export function captureMessage(m: string) {
  console.warn('[sentry preview] captureMessage', m);
}
export function setUser() {}
export function setTag() {}
export function setContext() {}
export function addBreadcrumb() {}
export function withScope(fn: (scope: unknown) => void) {
  fn({ setTag() {}, setExtra() {}, setContext() {}, setLevel() {} });
}
export function reactNavigationIntegration() {
  return { registerNavigationContainer() {} };
}
export function mobileReplayIntegration() {
  return {};
}
export function ErrorBoundary({ children }: { children?: React.ReactNode; fallback?: unknown }) {
  return <>{children}</>;
}
export const Severity = { Error: 'error', Warning: 'warning', Info: 'info' };
