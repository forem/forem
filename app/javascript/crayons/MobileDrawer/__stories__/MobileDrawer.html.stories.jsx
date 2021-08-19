/* eslint-disable jsx-a11y/no-static-element-interactions */
/* eslint-disable jsx-a11y/click-events-have-key-events */
// Disabled for the file due to issues disabling for individual JSX lines.
// These are disabled to allow the "click outside to close" functionality
import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import notes from './drawers.md';

import '../../storybook-utilities/designSystem.scss';

export default {
  title: 'Components/MobileDrawer/HTML',
  parameters: { notes },
};

export const Default = () => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  useEffect(() => {
    const keyupListener = (e) => {
      if (e.key === 'Escape') {
        setIsDrawerOpen(false);
      }
    };
    document.addEventListener('keyup', keyupListener);
    return () => document.removeEventListener('keyup', keyupListener);
  }, []);

  return (
    <div>
      <button className="crayons-btn" onClick={() => setIsDrawerOpen(true)}>
        Open drawer
      </button>
      {isDrawerOpen && (
        <div class="crayons-mobile-drawer">
          <div
            class="crayons-mobile-drawer__overlay"
            onClick={() => setIsDrawerOpen(false)}
          />
          <div
            aria-label="Example MobileDrawer"
            aria-modal="true"
            class="crayons-mobile-drawer__content"
            role="dialog"
          >
            <h2 className="mb-4">Lorem ipsum</h2>
            <button
              className="crayons-btn"
              onClick={() => setIsDrawerOpen(false)}
            >
              OK
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

Default.story = {
  name: 'default',
};
