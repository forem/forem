export const WINDOW_MODAL_ID = 'window-modal';

let pendingWindowModalPromise = null;

/**
 * Ensures the `windowModal` pack (`@crayons/Modal` + Preact `render`) is loaded
 * and returns `{ renderWindowModal, unmountWindowModal }`.
 *
 * @returns {Promise<{ renderWindowModal: Function, unmountWindowModal: Function }>}
 */
export function loadWindowModalBundle() {
  if (typeof window !== 'undefined') {
    if (window.Forem?.renderWindowModal) {
      return Promise.resolve({
        renderWindowModal: window.Forem.renderWindowModal,
        unmountWindowModal: window.Forem.unmountWindowModal,
      });
    }
    try {
      if (
        window.parent &&
        window.parent !== window &&
        window.parent.Forem?.renderWindowModal
      ) {
        return Promise.resolve({
          renderWindowModal: window.parent.Forem.renderWindowModal,
          unmountWindowModal: window.parent.Forem.unmountWindowModal,
        });
      }
    } catch {
      // Ignore cross-origin parent access errors
    }
  }

  if (pendingWindowModalPromise) {
    return pendingWindowModalPromise;
  }

  const metaTag = document.querySelector('meta[name="window-modal-script"]');
  const scriptSrc = metaTag?.content || '/assets/windowModal.js';

  pendingWindowModalPromise = new Promise((resolve, reject) => {
    const existingScript = document.querySelector(
      `script[src="${scriptSrc}"], script[data-window-modal-bundle="true"]`,
    );
    const script = existingScript || document.createElement('script');

    const cleanupFailure = (err) => {
      pendingWindowModalPromise = null;
      if (!existingScript) {
        script.remove();
      }
      reject(err);
    };

    script.addEventListener(
      'load',
      () => {
        if (window.Forem?.renderWindowModal) {
          resolve({
            renderWindowModal: window.Forem.renderWindowModal,
            unmountWindowModal: window.Forem.unmountWindowModal,
          });
        } else {
          cleanupFailure(
            new Error(
              'windowModal bundle loaded without registering renderWindowModal',
            ),
          );
        }
      },
      { once: true },
    );

    script.addEventListener(
      'error',
      () => {
        cleanupFailure(new Error(`Failed to load ${scriptSrc}`));
      },
      { once: true },
    );

    if (!existingScript) {
      script.src = scriptSrc;
      script.defer = true;
      script.dataset.windowModalBundle = 'true';
      document.head.appendChild(script);
    }
  });

  return pendingWindowModalPromise;
}

export function resetWindowModalLoaderForTests() {
  pendingWindowModalPromise = null;
}
