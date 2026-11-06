import { initKeyboardShortcuts } from '../utilities/keyboardShortcuts';

/**
 * Registers the `Escape` shortcut for closing `#global-signup-modal` and cleans up any prior listener.
 */
function setupSignupModalShortcuts() {
  window.__signupModalShortcutsCleanup?.();

  if (!document.getElementById('global-signup-modal')) {
    return;
  }

  const cleanupEscape = initKeyboardShortcuts({
    Escape() {
      const modal = document.getElementById('global-signup-modal');
      modal?.classList.add('hidden');
    },
  });

  const cleanup = () => {
    cleanupEscape?.();
    if (window.__signupModalShortcutsCleanup === cleanup) {
      window.__signupModalShortcutsCleanup = null;
    }
  };

  window.__signupModalShortcutsCleanup = cleanup;
}

if (document.readyState !== 'loading') {
  setupSignupModalShortcuts();
} else {
  document.addEventListener('DOMContentLoaded', setupSignupModalShortcuts);
}
