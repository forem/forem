export function isNativeAndroid() {
  return (
    navigator.userAgent === 'DEV-Native-android' &&
    typeof AndroidBridge !== 'undefined' &&
    AndroidBridge !== null
  );
}
