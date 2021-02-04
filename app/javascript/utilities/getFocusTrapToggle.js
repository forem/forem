import { createFocusTrap } from 'focus-trap';

/**
 * Returns a toggle which shows/hides the given element (e.g. modal) within a focus trap by toggling the '.hidden' class
 *
 * @example
 * import { getFocusTrapToggle } from "@utilities/getFocusTrapToggle";
 *
 * function initializeModal() {
 *   const toggleModalVisibility = getFocusTrapToggle('#example-modal');
 *   document.getElementById('example-modal-activator-button').addEventListener('click', toggleModalVisibility);
 * }
 *
 * @param {string} containerSelector The CSS selector for the element where visibility is to be toggled and focus trapped
 */
export function getFocusTrapToggle(containerSelector) {
  const focusTrap = createFocusTrap(containerSelector, {
    onDeactivate: deactivateTrap,
  });

  let isTrapActive = false;
  const container = document.querySelector(containerSelector);

  function deactivateTrap() {
    container.classList.add('hidden');
    focusTrap.deactivate();
    isTrapActive = false;
  }

  function activateTrap() {
    container.classList.remove('hidden');
    focusTrap.activate();
    isTrapActive = true;
  }

  function toggleFocusTrap() {
    if (isTrapActive) {
      deactivateTrap();
    } else {
      activateTrap();
    }
  }

  return toggleFocusTrap;
}
