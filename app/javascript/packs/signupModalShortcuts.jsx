import { initKeyboardShortcuts } from '../utilities/keyboardShortcuts';

let cleanupSignupShortcuts = null;

function setupSignupModalShortcuts() {
  if (!document.getElementById('global-signup-modal')) {
    return;
  }

  cleanupSignupShortcuts?.();
  cleanupSignupShortcuts = initKeyboardShortcuts({
    Escape() {
      const modal = document.getElementById('global-signup-modal');
      modal?.classList.add('hidden');
    },
  });
}

if (document.readyState !== 'loading') {
  setupSignupModalShortcuts();
} else {
  document.addEventListener('DOMContentLoaded', setupSignupModalShortcuts);
}
