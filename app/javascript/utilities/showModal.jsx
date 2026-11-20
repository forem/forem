import {
  WINDOW_MODAL_ID,
  loadWindowModalBundle,
} from '@utilities/windowModalLoader';

// Unique ID applied to modals created using the showWindowModal function
export { WINDOW_MODAL_ID };

/**
 * This helper function presents content inside a Preact modal.
 *
 * The modal content may be passed either as:
 * - the actual HTML (using modalContent prop), which will be dropped straight into the modal
 * - a CSS selector (using contentSelector prop), which will be used to locate the HTML content on the current page before dropping it into the modal
 *
 * Only one modal will be presented at any given time. All additional props will be passed directly to the Modal component.
 *
 * @param {Object} args
 * @param {HTMLElement} args.modalContent The HTML to display inside of the modal
 * @param {string} args.contentSelector The CSS query to locate the HTML to be presented in the modal, as an alternative to passing the actual HTML (e.g. '#my-modal-content')
 * @param {Function} args.onOpen A callback function to run when the modal opens. This can be useful, for example, to attach any event listeners to items inside the modal.
 * @param {Object} args.document Allows us to specify which "document" is relevant; e.g. use within iframes.
 */
export const showWindowModal = async (options) => {
  const { renderWindowModal } = await loadWindowModalBundle();
  if (typeof renderWindowModal === 'function') {
    renderWindowModal(options);
  }
};

/**
 * This helper function closes any currently open window modal. This can be useful, for example, if your modal contains a "cancel" button.
 */
export const closeWindowModal = async (document = window.document) => {
  const currentModalContainer = document.getElementById(WINDOW_MODAL_ID);
  if (!currentModalContainer) {
    return;
  }
  const { unmountWindowModal } = await loadWindowModalBundle();
  if (typeof unmountWindowModal === 'function') {
    unmountWindowModal(document);
  }
};
