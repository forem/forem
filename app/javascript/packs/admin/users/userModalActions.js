import { WINDOW_MODAL_ID } from '@utilities/showModal';

const getModalContent = () => document.getElementById(WINDOW_MODAL_ID);

export const initializeAddOrganizationContent = ({ userName, userId }) => {
  const modalContent = getModalContent();

  // Set the user ID for the form
  modalContent.querySelector('#organization_membership_user_id').value =
    parseInt(userId, 10);
  // Display the user's name in the modal
  modalContent.querySelector('.js-user-name').innerText = userName;
};

export const initializeAddRoleContent = ({ formAction }) => {
  getModalContent().querySelector('.js-add-role-form').action = formAction;
};

export const initializeAdjustCreditBalanceContent = ({
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

export const initializeUnpublishAllPostsContent = ({
  formAction,
  userName,
}) => {
  const modalContent = getModalContent();
  modalContent.querySelector('.js-unpublish-form').action = formAction;
  modalContent
    .querySelectorAll('.js-user-name')
    .forEach((span) => (span.innerText = userName));
};

export const initializeBanishContent = ({
  formAction,
  userName,
  banishableUser,
}) => {
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
