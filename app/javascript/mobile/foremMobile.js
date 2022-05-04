import { request } from '@utilities/http';
import { isNativeIOS, isNativeAndroid } from '@utilities/runtime';

export function foremMobileNamespace() {
  return {
    retryDelayMs: 700,
    getUserData() {
      return document.body.dataset.user;
    },
    getInstanceMetadata() {
      return JSON.stringify({
        name: document.querySelector("meta[property='forem:name']")['content'],
        logo: document.querySelector("meta[property='forem:logo']")['content'],
        domain: document.querySelector("meta[property='forem:domain']")[
          'content'
        ],
      });
    },
    registerDeviceToken(token, appBundle, platform) {
      request(`/users/devices`, {
        method: 'POST',
        body: { token, platform, app_bundle: appBundle },
        credentials: 'same-origin',
      })
        .then((response) => response.json())
        .then((response) => {
          if (
            !isNaN(parseInt(response.id, 10)) &&
            response.error == undefined
          ) {
            // Clear the interval if the registration succeeded
            clearInterval(window.ForemMobile.deviceRegistrationInterval);
            window.ForemMobile.retryDelayMs = 700;
          } else {
            // Registration failed - throw and log error message
            throw new Error(response.error);
          }
        })
        .catch((error) => {
          Honeybadger.notify(error);

          // Increase backoff delay time
          if (window.ForemMobile.retryDelayMs < 20000) {
            window.ForemMobile.retryDelayMs =
              window.ForemMobile.retryDelayMs * 2;
          }

          // Attempt to register again after delay
          setTimeout(() => {
            window.ForemMobile.registerDeviceToken(token, appBundle, platform);
          }, window.ForemMobile.retryDelayMs);
        });
    },
    unregisterDeviceToken(userId, token, appBundle, platform) {
      request(`/users/devices/${userId}`, {
        method: 'DELETE',
        body: { token, platform, app_bundle: appBundle },
        credentials: 'same-origin',
      });
    },
    injectJSMessage(message) {
      const event = new CustomEvent('ForemMobile', { detail: message });
      document.dispatchEvent(event);
    },
    injectNativeMessage(namespace, message) {
      try {
        if (isNativeIOS(namespace)) {
          window.webkit.messageHandlers[namespace].postMessage(message);
        } else if (isNativeAndroid(`${namespace}Message`)) {
          AndroidBridge[`${namespace}Message`](JSON.stringify(message));
        }
      } catch (error) {
        Honeybadger.notify(error);
      }
    },
    userSessionBroadcast() {
      const currentUser = document.body.dataset.user;
      if (currentUser) {
        window.ForemMobile.injectNativeMessage(
          'userLogin',
          JSON.parse(currentUser),
        );
      } else {
        window.ForemMobile.injectNativeMessage('userLogout', {});
      }
    },
  };
}
