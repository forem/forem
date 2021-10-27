/* global Runtime, fetchBaseData */
if (Runtime != null && Runtime.currentMedium() === 'ForemWebView') {
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
      const params = JSON.stringify({
        token,
        platform,
        app_bundle: appBundle,
      });
      const csrfToken = document.querySelector(
        "meta[name='csrf-token']",
      )?.content;
      fetch('/users/devices', {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
        },
        body: params,
        credentials: 'same-origin',
      })
        .then((response) => {
          if (response.status === 201) {
            // Clear the interval if the registration succeeded
            clearInterval(window.ForemMobile.deviceRegistrationInterval);
            window.ForemMobile.retryDelayMs = 700;
          } else {
            throw new Error('REQUEST FAILED');
          }
        })
        .catch(() => {
          // Re-attempt with exponential backoff up to ~20s delay
          clearInterval(window.ForemMobile.deviceRegistrationInterval);
          if (window.ForemMobile.retryDelayMs < 20000) {
            window.ForemMobile.retryDelayMs =
              window.ForemMobile.retryDelayMs * 2;
          }

          window.ForemMobile.deviceRegistrationInterval = setInterval(
            window.registerDeviceToken,
            window.ForemMobile.retryDelayMs,
          );

          // Force a refresh on BaseData (CSRF Token)
          fetchBaseData();
        });
      window.deviceRegistrationInterval = setInterval(
        window.registerDeviceToken,
        window.ForemMobile.retryDelayMs,
      );
    },
    unregisterDeviceToken(userId, token, appBundle, platform) {
      const params = JSON.stringify({
        token,
        platform,
        app_bundle: appBundle,
      });
      fetch(`/users/devices/${userId}`, {
        method: 'DELETE',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: params,
      });
    },
  };
}
