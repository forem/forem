import { initKeyboardShortcuts } from '../utilities/keyboardShortcuts';
import { initListNavigation } from '../utilities/listNavigation';

/**
 * Registers keyboard shortcuts (`b`, `j`, `k`) for story feeds and cleans up any prior listeners.
 */
function setupHomePageFeedShortcuts() {
  window.__homePageFeedShortcutsCleanup?.();

  if (!document.getElementById('main-content')) {
    return;
  }

  const cleanupKeyShortcuts = initKeyboardShortcuts({
    b: (event) => {
      const article = event.target?.closest('.crayons-story');

      if (!article) return;

      article.querySelector('button[id^=article-save-button-]')?.click();
    },
  });

  const cleanupListNav = initListNavigation(
    '.crayons-story',
    'a.crayons-story__hidden-navigation-link',
    'div.paged-stories,div.substories',
  );

  const cleanup = () => {
    cleanupKeyShortcuts?.();
    cleanupListNav?.();
    if (window.__homePageFeedShortcutsCleanup === cleanup) {
      window.__homePageFeedShortcutsCleanup = null;
    }
  };

  window.__homePageFeedShortcutsCleanup = cleanup;
}

if (document.readyState !== 'loading') {
  setupHomePageFeedShortcuts();
} else {
  document.addEventListener('DOMContentLoaded', setupHomePageFeedShortcuts);
}
