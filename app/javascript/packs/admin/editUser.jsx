import { initializeAddOrganizationContent } from './users/userModalActions';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { showWindowModal } from '@utilities/showModal';

function adjustCreditRange(event) {
  const {
    target: { value, name, form },
  } = event;

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
}

function enableEvents(key, enabled = true) {
  if (!eventMap.has(key)) {
    return;
  }

  const [eventType, handler] = eventMap.get(key);

  modalContainer[enabled ? 'addEventListener' : 'removeEventListener'](
    eventType,
    handler,
  );
}

// Keys are the modalContentSelector data attribute on a button that opens a modal.
// Values are a tuple containing the event type and handler to add to the modal container.
const eventMap = new Map();

eventMap.set('.js-adjust-balance', ['change', adjustCreditRange]);

const modalContentInitializers = {
  '.js-add-organization': initializeAddOrganizationContent,
};

// Append an empty div to the end of the document so that is does not affect the layout.
const modalContainer = document.createElement('div');
document.body.appendChild(modalContainer);

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  const { dataset } = event.target;

  if (!Object.prototype.hasOwnProperty.call(dataset, 'modalTrigger')) {
    // We're not trying to trigger a modal.
    return;
  }

  event.preventDefault();

  const { modalTitle, modalSize, modalContentSelector } = dataset;

  showWindowModal({
    contentSelector: modalContentSelector,
    title: modalTitle,
    size: modalSize,
    onOpen: () => {
      enableEvents(modalContentSelector);
      modalContentInitializers[modalContentSelector]?.(dataset);
    },
  });
};

document.body.addEventListener('click', openModal);
