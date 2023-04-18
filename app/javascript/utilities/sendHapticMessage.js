export function sendHapticMessage(message) {
  try {
    if (
      window &&
      window.webkit &&
      window.webkit.messageHandlers &&
      window.webkit.messageHandlers.haptic
    ) {
      window.webkit.messageHandlers.haptic.postMessage(message);
    }
  } catch (err) {
    console.log(err.message); // eslint-disable-line no-console
  }
}
