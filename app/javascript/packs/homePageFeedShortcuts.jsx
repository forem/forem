import { initKeyboardShortcuts } from '../utilities/keyboardShortcuts';
import { initListNavigation } from '../utilities/listNavigation';

let cleanupKeyShortcuts = null;
let cleanupListNav = null;

function setupHomePageFeedShortcuts() {
  if (!document.getElementById('main-content')) {
    return;
  }

  cleanupKeyShortcuts?.();
  cleanupListNav?.();

  cleanupKeyShortcuts = initKeyboardShortcuts({
    b: (event) => {
      const article = event.target?.closest('.crayons-story');

      if (!article) return;

      article.querySelector('button[id^=article-save-button-]')?.click();
    },
  });

  cleanupListNav = initListNavigation(
    '.crayons-story',
    'a.crayons-story__hidden-navigation-link',
    'div.paged-stories,div.substories',
  );
}

if (document.readyState !== 'loading') {
  setupHomePageFeedShortcuts();
} else {
  document.addEventListener('DOMContentLoaded', setupHomePageFeedShortcuts);
}
