/**
 * This function is used to check that is Device is android native or not
 */
export function isNativeAndroid() {
  return (
    navigator.userAgent === 'DEV-Native-android' &&
    typeof AndroidBridge !== 'undefined' &&
    AndroidBridge !== null
  );
}
