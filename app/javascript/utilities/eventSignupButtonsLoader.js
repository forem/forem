let eventSignupButtonsPromise;

/**
 * Resets cached promise state between Jest tests.
 */
export function resetEventSignupButtonsLoaderForTests() {
  eventSignupButtonsPromise = undefined;
}

/**
 * Checks whether the current DOM contains any event signup buttons.
 *
 * @returns {boolean} True when at least one `[data-event-signup-button="true"]` element is present
 */
export function shouldLoadEventSignupButtons() {
  return Boolean(document.querySelector('[data-event-signup-button="true"]'));
}

/**
 * Loads the `eventSignupButtons` bundle once using the URL from `meta[name="event-signup-buttons-script"]`.
 *
 * @returns {Promise<void>} Resolves when the script finishes loading or if unavailable
 */
export function loadEventSignupButtonsBundle() {
  if (typeof window.eventSignupCleanup === 'function') {
    return Promise.resolve();
  }

  if (eventSignupButtonsPromise) {
    return eventSignupButtonsPromise;
  }

  const scriptMeta = document.querySelector(
    'meta[name="event-signup-buttons-script"]',
  );
  const scriptSrc = scriptMeta?.getAttribute('content');

  if (!scriptSrc) {
    return Promise.resolve();
  }

  const existingScript = document.querySelector(`script[src="${scriptSrc}"]`);

  eventSignupButtonsPromise = new Promise((resolve) => {
    if (existingScript) {
      existingScript.addEventListener('load', () => resolve(), { once: true });
      existingScript.addEventListener(
        'error',
        () => {
          existingScript.remove();
          eventSignupButtonsPromise = undefined;
          resolve();
        },
        { once: true },
      );
      return;
    }

    const script = document.createElement('script');
    script.src = scriptSrc;
    script.defer = true;
    script.onload = () => resolve();
    script.onerror = () => {
      script.remove();
      eventSignupButtonsPromise = undefined;
      resolve();
    };
    document.head.appendChild(script);
  });

  return eventSignupButtonsPromise;
}

/**
 * Conditionally loads the `eventSignupButtons` bundle when event signup buttons exist in the DOM.
 *
 * @returns {Promise<void>}
 */
export function maybeLoadEventSignupButtons() {
  if (!shouldLoadEventSignupButtons()) {
    return Promise.resolve();
  }

  return loadEventSignupButtonsBundle();
}
