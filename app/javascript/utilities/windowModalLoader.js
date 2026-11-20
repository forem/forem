import { createAssetBundleLoader } from './loadAssetBundle';

export const WINDOW_MODAL_ID = 'window-modal';

const windowModalBundleLoader = createAssetBundleLoader({
  metaName: 'window-modal-script',
  fallbackSrc: '/assets/windowModal.js',
  dataAttribute: 'windowModalBundle',
  getReadyValue: () => {
    if (window.Forem?.renderWindowModal) {
      return {
        renderWindowModal: window.Forem.renderWindowModal,
        unmountWindowModal: window.Forem.unmountWindowModal,
      };
    }
    try {
      if (
        window.parent &&
        window.parent !== window &&
        window.parent.Forem?.renderWindowModal
      ) {
        return {
          renderWindowModal: window.parent.Forem.renderWindowModal,
          unmountWindowModal: window.parent.Forem.unmountWindowModal,
        };
      }
    } catch {
      // Ignore cross-origin parent access errors
    }
    return null;
  },
  errorMessage:
    'windowModal bundle loaded without registering renderWindowModal',
});

/**
 * Ensures the `windowModal` pack (`@crayons/Modal` + Preact `render`) is loaded
 * and returns `{ renderWindowModal, unmountWindowModal }`.
 *
 * @returns {Promise<{ renderWindowModal: Function, unmountWindowModal: Function }>}
 */
export function loadWindowModalBundle() {
  return windowModalBundleLoader.load();
}

export function resetWindowModalLoaderForTests() {
  windowModalBundleLoader.reset();
}
