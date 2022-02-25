import { initializeDropdown } from '@utilities/dropdownUtils';

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

function getModalContents(modalContentSelector) {
  if (!modalContents.has(modalContentSelector)) {
    const modelContentElement = document.querySelector(modalContentSelector);
    const modalContent = modelContentElement.innerHTML;

    // Remove the element from the DOM to avoid duplicate ID errors in regards to a11y.
    modelContentElement.remove();
    modalContents.set(modalContentSelector, modalContent);
  }

  return modalContents.get(modalContentSelector);
}

let preact;
let AdminModal;
const modalContents = new Map();

// Keys are the modalContentSelector data attribute on a button that opens a modal.
// Values are a tuple containing the event type and handler to add to the modal container.
const eventMap = new Map();

eventMap.set('#adjust-balance', ['change', adjustCreditRange]);

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

  // Only load Preact if we haven't already.
  if (!preact) {
    [preact, { Modal: AdminModal }] = await Promise.all([
      import('preact'),
      import('@crayons/Modal/Modal'),
    ]);
  }

  const { h, render } = preact;

  const { modalTitle, modalSize, modalContentSelector } = dataset;

  enableEvents(modalContentSelector);

  render(
    <AdminModal
      title={modalTitle}
      size={modalSize}
      onClose={() => {
        render(null, modalContainer);
        enableEvents(modalContentSelector, false);
      }}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: getModalContents(modalContentSelector),
        }}
      />
    </AdminModal>,
    modalContainer,
  );
};

document.body.addEventListener('click', openModal);
