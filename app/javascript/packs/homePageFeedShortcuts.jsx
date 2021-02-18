import { h, render, Fragment } from 'preact';
import { ListNavigation } from '../shared/components/useListNavigation';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('main-content');

  render(
    <Fragment>
      <KeyboardShortcuts
        shortcuts={{
          b: (event) => {
            const article = event.target?.closest('.crayons-story');

            if (!article) return;

            article.querySelector('button[id^=article-save-button-]')?.click();
          },
        }}
      />
      <ListNavigation
        itemSelector=".crayons-story"
        focusableSelector="a.crayons-story__hidden-navigation-link"
        waterfallItemContainerSelector="div.paged-stories,div.substories"
      />
    </Fragment>,
    root,
  );
});
