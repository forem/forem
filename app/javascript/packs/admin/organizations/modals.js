import { showWindowModal } from '@utilities/showModal';

const modalContents = new Map();
/**
 * Helper function to handle finding and caching modal content. Since our Preact modal helper works by duplicating HTML content,
 * and our user modals rely on IDs to label form controls, we remove the original hidden content from the DOM to avoid ID conflicts.
 *
 * @param {string} modalContentSelector The CSS selector used to identify the correct modal content
 */
const getModalContents = (modalContentSelector) => {
  if (!modalContents.has(modalContentSelector)) {
    const modalContentElement = document.querySelector(modalContentSelector);
    const modalContent = modalContentElement.innerHTML;

    modalContentElement.remove();
    modalContents.set(modalContentSelector, modalContent);
  }

  return modalContents.get(modalContentSelector);
};

/**
 * Helper function for views which use admin user modals. May be attached as an event listener, and its actions will only be triggered
 * if the target of the event is a recognised user modal trigger.
 *
 * @param {Object} event
 */
export const showOrganizationModal = (event) => {
  const { dataset } = event.target;

  if (!Object.prototype.hasOwnProperty.call(dataset, 'modalContentSelector')) {
    // We're not trying to trigger a modal.
    return;
  }

  event.preventDefault();

  const { modalTitle, modalSize, modalContentSelector } = dataset;

  showWindowModal({
    modalContent: getModalContents(modalContentSelector),
    title: modalTitle,
    size: modalSize,
  });
};
