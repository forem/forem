let eventSignupButtonsPromise;

export function resetEventSignupButtonsLoaderForTests() {
  eventSignupButtonsPromise = undefined;
}

export function shouldLoadEventSignupButtons() {
  return Boolean(document.querySelector('[data-event-signup-button="true"]'));
}

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
      eventSignupButtonsPromise = undefined;
      resolve();
    };
    document.head.appendChild(script);
  });

  return eventSignupButtonsPromise;
}

export function maybeLoadEventSignupButtons() {
  if (!shouldLoadEventSignupButtons()) {
    return Promise.resolve();
  }

  return loadEventSignupButtonsBundle();
}
