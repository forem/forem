export function getFocusTrapToggle(containerSelector, activatorSelector) {
  const KEYCODE_TAB = 9;
  const KEYCODE_ESC = 27;

  let isTrapActive = false;

  const container = document.querySelector(containerSelector);
  const activatorButton = document.querySelector(activatorSelector);

  const focusableEls = container.querySelectorAll(
    'a[href]:not([disabled]), button:not([disabled]), textarea:not([disabled]), input[type="text"]:not([disabled]), input[type="radio"]:not([disabled]), input[type="checkbox"]:not([disabled]), select:not([disabled])',
  );

  const firstFocusableEl = focusableEls[0];
  const lastFocusableEl = focusableEls[focusableEls.length - 1];

  function keyPressListener(e) {
    const isTabPressed = e.key === 'Tab' || e.keyCode === KEYCODE_TAB;
    const isEscapePressed = e.key === 'Escape' || e.keyCode === KEYCODE_ESC;

    if (isEscapePressed) {
      deactivateTrap();
      return;
    }

    if (!isTabPressed) {
      return;
    }

    if (e.shiftKey) {
      /* shift + tab */ if (document.activeElement === firstFocusableEl) {
        lastFocusableEl.focus();
        e.preventDefault();
      }
    } /* tab */ else if (document.activeElement === lastFocusableEl) {
      firstFocusableEl.focus();
      e.preventDefault();
    }
  }

  function deactivateTrap() {
    container.classList.add('hidden');
    activatorButton.focus();
    container.removeEventListener('keydown', keyPressListener);
    isTrapActive = false;
  }

  function activateTrap() {
    container.classList.remove('hidden');
    firstFocusableEl.focus();
    container.addEventListener('keydown', keyPressListener);
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
