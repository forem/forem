import { h } from 'preact';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { instantClickRender } from '@utilities/preact/render';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('global-signup-modal');

  instantClickRender(
    <KeyboardShortcuts
      shortcuts={{
        Escape() {
          const modal = document.getElementById('global-signup-modal');
          modal?.classList.add('hidden');
        },
      }}
    />,
    root,
  );
});
