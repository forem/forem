/* global Runtime */
import { waitOnBaseData } from '../utilities/waitOnBaseData';
import { request } from '@utilities/http';

function loadForemMobileNamespace() {
  window.ForemMobile = {
    retryDelayMs: 700,
    getUserData() {
      const userStatus = document
        .getElementsByTagName('body')[0]
        .getAttribute('data-user-status');
      if (userStatus === 'logged-in') {
        return document
          .getElementsByTagName('body')[0]
          .getAttribute('data-user');
      }
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
  };
}

// Initialize (when ready)
waitOnBaseData()
  .then(() => {
    if (Runtime.currentMedium() === 'ForemWebView') {
      loadForemMobileNamespace();
    }
  })
  .catch((error) => {
    Honeybadger.notify(error);
  });
