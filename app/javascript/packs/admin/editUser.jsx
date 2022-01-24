import { AdminUserActionsModal } from '@admin/AdminUserActionsModal';
import { initializeDropdown } from '@utilities/dropdownUtils';

let preact;
let Modal;

const modalTriggers = document.querySelectorAll('[data-modal-trigger]');

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  // Append an empty div to the end of the document so that is does not affect the layout.
  const modalContainer = document.createElement('div');
  document.body.appendChild(modalContainer);

  const { target: trigger } = event;

  // Only load Preact if we haven't already.
  if (!preact || !AdminUserActionsModal) {
    [preact, { AdminUserActionsModal: Modal }] = await Promise.all([
      import('preact'),
      import('@admin'),
    ]);
  }

  const { h, render } = preact;

  // TODO: Where are we pulling the modal body from?
  render(
    <Modal title={trigger.dataset.modalTitle} size={trigger.dataset.modalSize}>
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: document.querySelector(trigger.dataset.modalContentSelector)
            .innerHTML,
        }}
      />
    </Modal>,
    modalContainer,
  );
};

modalTriggers.forEach((trigger) =>
  trigger.addEventListener('click', openModal),
);
