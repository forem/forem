import { h, render } from 'preact';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('hide-comments-modal');

  render(
    <KeyboardShortcuts
      shortcuts={{
        Escape() {
          const modal = document.getElementById('hide-comments-modal');
          modal?.classList.add('hidden');
        },
      }}
    />,
    root,
  );
});
