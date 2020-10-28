import { h, render } from 'preact';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.querySelector('#articles-list');

  render(
    <KeyboardShortcuts
      shortcuts={{
        b: (event) => {
          const article = event.target?.closest('.crayons-story');

          if (!article) return;

          article.querySelector('button[id^=article-save-button-]')?.click();
        },
      }}
    />,
    root,
  );
});
