/**
 * Determines whether or not a device is a touch device.
 *
 * @returns true if a touch device, otherwise false.
 */
function isTouchDevice() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|DEV-Native-ios/i.test(
    navigator.userAgent,
  );
}
