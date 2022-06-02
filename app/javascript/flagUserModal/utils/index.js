import { h, render } from 'preact';
import { FlagUserModal } from '../../packs/flagUserModal';

/**
 * Shows or hides the flag user modal.
 */
export function toggleFlagUserModal() {
  const modalContainer = top.document.getElementsByClassName(
    'flag-user-modal-container',
  )[0];
  modalContainer.classList.toggle('hidden');

  if (!modalContainer.classList.contains('hidden')) {
    top.window.scrollTo(0, 0);
    top.document.body.style.height = '100vh';
    top.document.body.style.overflowY = 'hidden';
  } else {
    top.document.body.style.height = 'inherit';
    top.document.body.style.overflowY = 'inherit';
  }
}

/**
 * Initializes the flag user modal for the given author ID.
 *
 * @param {number} authorId
 */
export function initializeFlagUserModal(authorId) {
  // Check whether context is ModCenter or Friday-Night-Mode
  const modContainer = document.getElementById('mod-container');

  if (!modContainer) {
    return;
  }

  const [flagUserModalContainer] = document.getElementsByClassName(
    'flag-user-modal-container',
  );

  const flaggedUser =
    flagUserModalContainer.getAttribute('user-flagged') === 'true';

  render(
    <FlagUserModal authorId={authorId} flaggedUser={flaggedUser} />,
    flagUserModalContainer,
  );
}

/**
 * Changes the Flag user button label to
 * "Unflag user" or "Flag user" depending on the current state
 */
export function changeFlagUserButtonLabel(flaggedUser) {
  const iframe =
    document.getElementById('mod-container').contentWindow.document;

  iframe.getElementById('open-flag-user-modal').innerText = flaggedUser
    ? 'Unflag user'
    : 'Flag user';
}

export function showSnackbarItem(message) {
  top.addSnackbarItem({ message, addCloseButton: true });
}
