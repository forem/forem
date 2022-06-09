import { WINDOW_MODAL_ID, showWindowModal } from '@utilities/showModal';

const getModalContent = () => document.getElementById(WINDOW_MODAL_ID);

/**
 * Populate the add organization modal with user data
 *
 * @param {Object} dataset
 * @param {string} dataset.userName
 * @param {string} dataset.userId
 */
const initializeAddOrganizationContent = ({ userName, userId }) => {
  const modalContent = getModalContent();

  modalContent.querySelector('#organization_membership_user_id').value =
    parseInt(userId, 10);

  modalContent.querySelector('.js-user-name').innerText = userName;
};

/**
 * Populate the add role modal with its action
 *
 * @param {Object} dataset
 * @param {string} dataset.formAction The URL for the form action
 */
const initializeAddRoleContent = ({ formAction }) => {
  getModalContent().querySelector('.js-add-role-form').action = formAction;
};

/**
 * Populate the adjust credits modal with user data
 *
 * @param {Object} dataset
 * @param {string} dataset.userName
 * @param {string} dataset.unspentCreditsCount The user's current credit balance
 * @param {string} dataset.formAction The URL for the form action
 */
const initializeAdjustCreditBalanceContent = ({
  userName,
  unspentCreditsCount,
  formAction,
}) => {
  const modalContent = getModalContent();

  const form = modalContent.querySelector('.js-adjust-credits-form');
  form.action = formAction;

  const canRemoveCredits = unspentCreditsCount > 0;
  if (canRemoveCredits) {
    const remove = document.createElement('option');
    remove.value = 'Remove';
    remove.innerText = 'Remove';

    modalContent.querySelector('.js-credit-action').appendChild(remove);
  }

  modalContent.querySelector('.js-user-name').innerText = userName;
  modalContent.querySelector('.js-unspent-credits-count').innerText =
    unspentCreditsCount;
  modalContent.querySelector('.js-credit-amount').dataset.unspentCredits =
    unspentCreditsCount;

  form.addEventListener('change', ({ target: { value, name, form } }) => {
    if (name === 'user[credit_action]') {
      const creditAmount = form['user[credit_amount]'];

      if (value === 'Add') {
        if (creditAmount.getAttribute('data-old-max')) {
          creditAmount.setAttribute(
            'max',
            creditAmount.getAttribute('data-old-max'),
          );
        }
      } else {
        creditAmount.setAttribute(
          'data-old-max',
          creditAmount.getAttribute('max'),
        );
        creditAmount.setAttribute('max', creditAmount.dataset.unspentCredits);
      }
    }
  });
};

/**
 * Populate the unpublish all posts model with user data
 *
 * @param {Object} dataset
 * @param {string} dataset.formAction The URL for the form action
 * @param {string} dataset.userName
 */
const initializeUnpublishAllPostsContent = ({ formAction, userName }) => {
  const modalContent = getModalContent();
  modalContent.querySelector('.js-unpublish-form').action = formAction;
  modalContent
    .querySelectorAll('.js-user-name')
    .forEach((span) => (span.innerText = userName));
};

/**
 * Populate the banish modal with user data
 *
 * @param {Object} dataset
 * @param {string} dataset.formAction The URL for the form action
 * @param {string} dataset.userName
 * @param {string} dataset.banishableUser "true" or "false" - is it possible to banish this user
 */
const initializeBanishContent = ({ formAction, userName, banishableUser }) => {
  const modalContent = getModalContent();

  const banishable = banishableUser === 'true';
  const banishableContent = modalContent.querySelector('.js-banishable-user');
  const notBanishableContent = modalContent.querySelector(
    '.js-not-banishable-user',
  );

  if (banishable) {
    banishableContent.classList.remove('hidden');
    notBanishableContent.classList.add('hidden');
    modalContent.querySelector('.js-banish-form').action = formAction;
  } else {
    banishableContent.classList.add('hidden');
    notBanishableContent.classList.remove('hidden');
  }

  modalContent
    .querySelectorAll('.js-user-name')
    .forEach((span) => (span.innerText = userName));
};

const modalContentInitializers = {
  '#add-organization': initializeAddOrganizationContent,
  '#add-role-modal': initializeAddRoleContent,
  '#adjust-balance': initializeAdjustCreditBalanceContent,
  '#unpublish-all-posts': initializeUnpublishAllPostsContent,
  '#banish-for-spam': initializeBanishContent,
};

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
export const showUserModal = (event) => {
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
    onOpen: () => {
      modalContentInitializers[modalContentSelector]?.(dataset);
    },
  });
};
