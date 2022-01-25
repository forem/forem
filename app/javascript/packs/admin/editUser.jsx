import { initializeDropdown } from '@utilities/dropdownUtils';

let preact;
let AdminModal;

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

  render(
    <AdminModal
      title={modalTitle}
      size={modalSize}
      onClose={() => {
        render(null, modalContainer);
      }}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: document.querySelector(modalContentSelector).innerHTML,
        }}
      />
    </AdminModal>,
    modalContainer,
  );
};

document.body.addEventListener('click', openModal);
