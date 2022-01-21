import { AdminUserActionsModal } from '@admin/AdminUserActionsModal';
import { initializeDropdown } from '@utilities/dropdownUtils';

let preact;
let Modal;

const userEditActionsMenu = document.getElementById('options-dropdown');
const overviewContainer = document.getElementById('overview-container');

initializeDropdown({
  triggerElementId: 'options-dropdown-trigger',
  dropdownContentId: 'options-dropdown',
});

const openModal = async (event) => {
  // Append an empty div to the end of the document so that is does not affect the layout.
  const modalContainer = document.createElement('div');
  document.body.appendChild(modalContainer);

  const { target: potentialButton } = event;
  if (
    potentialButton.tagName !== 'BUTTON' ||
    Object.prototype.hasOwnProperty.call(potentialButton.dataset, 'noModal')
  ) {
    // The button that was clicked does not require a modal.
    return;
  }

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
    <Modal title={potentialButton.innerHTML}>Hello</Modal>,
    modalContainer,
  );
};

overviewContainer?.addEventListener('click', openModal);
userEditActionsMenu.addEventListener('click', openModal);
