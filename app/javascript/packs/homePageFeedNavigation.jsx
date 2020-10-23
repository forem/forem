import { h, render, Fragment } from 'preact';
import { ListNavigation } from '../shared/components/useListNavigation';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.querySelector('#articles-list');

  function followLink(event, blank = false) {
    if (event.target.matches('.crayons-story')) {
      const link = event.target.querySelector('a[id^=article-link-]');
      if (link && link.href) {
        if (blank) {
          window.open(link.href, '_blank');
        } else {
          window.location.href = link.href;
        }
      }
    }
  }

  render(
    <Fragment>
      <KeyboardShortcuts
        shortcuts={{
          Enter: followLink,
          'meta+Enter': (event) => followLink(event, true),
          'ctrl+Enter': (event) => followLink(event, true),
        }}
      />
      <ListNavigation
        elementSelector=".crayons-story"
        waterfallElementContainerSelector="div.paged-stories,div.substories"
      />
    </Fragment>,
    root,
  );
});
