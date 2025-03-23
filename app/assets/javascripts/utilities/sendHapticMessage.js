'use strict';

function sendHapticMessage(message) {
  try {
    if (
      window &&
      window.webkit &&
      window.webkit.messageHandlers &&
      window.webkit.messageHandlers.haptic
    ) {
      window.webkit.messageHandlers.haptic.postMessage(message);
    } else if (
      window &&
      window.ReactNativeWebView
    ) {
      window.ReactNativeWebView.postMessage(JSON.stringify({
        action: 'haptic',
        value: message,
      }));
    }
  } catch (err) {
    console.log(err.message); // eslint-disable-line no-console
  }
}
