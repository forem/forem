import { initializeDropdown } from '@utilities/dropdownUtils';

let preact;
let Modal;

// Append an empty div to the end of the document so that is does not affect the layout.
const modalContainer = document.createElement('div');
document.body.appendChild(modalContainer);

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  event.preventDefault();

  const { dataset = {} } = event.target;

  if (!Object.prototype.hasOwnProperty.call(dataset, 'modalTrigger')) {
    // We're not trying to trigger a modal.
    return;
  }

  // Only load Preact if we haven't already.
  if (!preact) {
    [preact, { AdminUserActionsModal: Modal }] = await Promise.all([
      import('preact'),
      import('@admin'),
    ]);
  }

  const { h, render } = preact;

  if (modalContainer) {
    // We've loaded a modal at least once in the modal container, so unmount it before rendering a new one.
    // This allows us to only ever append one div to the body.
    render(null, modalContainer);
  }

  const { modalTitle, modalSize, modalContentSelector } = dataset;

  // TODO: Where are we pulling the modal body from?
  render(
    <Modal title={modalTitle} size={modalSize}>
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: document.querySelector(modalContentSelector).innerHTML,
        }}
      />
    </Modal>,
    modalContainer,
  );
};

document.body.addEventListener('click', openModal);
