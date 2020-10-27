import { h, render } from 'preact';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.querySelector('#global-signup-modal');

  render(
    <KeyboardShortcuts
      shortcuts={{
        Escape() {
          const modal = document.querySelector('#global-signup-modal');
          modal?.classList.add('hidden');
        },
      }}
    />,
    root,
  );
});
