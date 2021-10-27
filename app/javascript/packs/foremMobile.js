/* global Runtime, fetchBaseData */

function initializeNamespaceWhenPageIsReady() {
  setTimeout(() => {
    // Wait for data-loaded so we can ensure initializers have executed. This
    // way we know the Runtime class will be available globally
    if (document.body.getAttribute('data-loaded') === 'true') {
      // We're ready to initialize
      if (Runtime.currentMedium() === 'ForemWebView') {
        loadForemMobileNamespace();
      }
    } else {
      // Page hasn't initialized yet. We need to wait until the page is ready
      initializeNamespaceWhenPageIsReady();
    }
  }, 100);
}

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
            // Registration failed - log error message
            Honeybadger.notify(response.error);
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

// Initialize (when ready)
initializeNamespaceWhenPageIsReady();
