import { WINDOW_MODAL_ID, showWindowModal } from '@utilities/showModal';

const getModalContent = () => document.getElementById(WINDOW_MODAL_ID);

const initializeAddOrganizationContent = ({ userName, userId }) => {
  const modalContent = getModalContent();

  modalContent.querySelector('#organization_membership_user_id').value =
    parseInt(userId, 10);

  modalContent.querySelector('.js-user-name').innerText = userName;
};

const initializeAddRoleContent = ({ formAction }) => {
  getModalContent().querySelector('.js-add-role-form').action = formAction;
};

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

const initializeUnpublishAllPostsContent = ({ formAction, userName }) => {
  const modalContent = getModalContent();
  modalContent.querySelector('.js-unpublish-form').action = formAction;
  modalContent
    .querySelectorAll('.js-user-name')
    .forEach((span) => (span.innerText = userName));
};

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
  '.js-add-organization': initializeAddOrganizationContent,
  '.js-add-role': initializeAddRoleContent,
  '.js-adjust-balance': initializeAdjustCreditBalanceContent,
  '.js-unpublish-all-posts': initializeUnpublishAllPostsContent,
  '.js-banish-for-spam': initializeBanishContent,
};

const modalContents = new Map();
const getModalContents = (modalContentSelector) => {
  if (!modalContents.has(modalContentSelector)) {
    const modalContentElement = document.querySelector(modalContentSelector);
    const modalContent = modalContentElement.innerHTML;

    // User modal content relies on IDs to label form controls. Since duplicate IDs in the DOM prevents
    // proper form label associations, we remove the original hidden content from the DOM and cache it for any later use.
    modalContentElement.remove();
    modalContents.set(modalContentSelector, modalContent);
  }

  return modalContents.get(modalContentSelector);
};

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
