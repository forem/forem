import { createFocusTrap } from 'focus-trap';

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
