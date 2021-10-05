/* eslint-disable jsx-a11y/no-static-element-interactions */
/* eslint-disable jsx-a11y/click-events-have-key-events */
// Disabled for the file due to issues disabling for individual JSX lines.
// These are disabled to allow the "click outside to close" functionality
import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import notes from './mobileDrawerNavigation.md';

export default {
  title: 'App Components/MobileDrawerNavigation/HTML',
  parameters: { notes },
};

export const Default = () => {
  const [isNavOpen, setIsNavOpen] = useState(false);

  const { href, hash } = window.location;
  const indexOfHash = href.indexOf(hash) || href.length;
  const baseStoryUrl = href.substr(0, indexOfHash);

  useEffect(() => {
    const keyupListener = (e) => {
      if (e.key === 'Escape') {
        setIsNavOpen(false);
      }
    };
    document.addEventListener('keyup', keyupListener);
    return () => document.removeEventListener('keyup', keyupListener);
  }, []);

  return (
    <div>
      <div class="flex justify-between">
        <h1>Link 1</h1>
        <button
          onClick={() => setIsNavOpen(true)}
          aria-label="Test navigation"
          class="crayons-btn crayons-btn--ghost crayons-btn--s crayons-btn--icon"
          type="button"
        >
          <svg height="24" width="24" xmlns="http://www.w3.org/2000/svg">
            <path
              clip-rule="evenodd"
              d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"
              fill-rule="evenodd"
            />
          </svg>
        </button>
      </div>
      {isNavOpen && (
        <div class="crayons-mobile-drawer">
          <div
            class="crayons-mobile-drawer__overlay"
            onClick={() => setIsNavOpen(false)}
          />
          <div
            aria-label="Test navigation"
            aria-modal="true"
            class="crayons-mobile-drawer__content"
            role="dialog"
          >
            <nav aria-label="Test navigation" class="drawer-navigation">
              <ul class="list-none">
                <li class="drawer-navigation__item py-2">
                  <a
                    aria-current={href === baseStoryUrl ? 'page' : null}
                    href={baseStoryUrl}
                  >
                    Link 1
                  </a>
                  <svg
                    aria-hidden="true"
                    class="check-icon"
                    fill="currentColor"
                    height="24"
                    viewBox="0 0 24 24"
                    width="24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M10 15.172l9.192-9.193 1.415 1.414L10 18l-6.364-6.364 1.414-1.414 4.95 4.95z" />
                  </svg>
                </li>
                <li class="drawer-navigation__item py-2">
                  <a
                    href={`${baseStoryUrl}/#2`}
                    aria-current={`#2` === hash ? 'page' : null}
                  >
                    Link 2
                  </a>
                  <svg
                    aria-hidden="true"
                    class="check-icon"
                    fill="currentColor"
                    height="24"
                    viewBox="0 0 24 24"
                    width="24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M10 15.172l9.192-9.193 1.415 1.414L10 18l-6.364-6.364 1.414-1.414 4.95 4.95z" />
                  </svg>
                </li>
                <li class="drawer-navigation__item py-2">
                  <a
                    href={`${baseStoryUrl}/#3`}
                    aria-current={`#3` === hash ? 'page' : null}
                  >
                    Link 3
                  </a>
                  <svg
                    aria-hidden="true"
                    class="check-icon"
                    fill="currentColor"
                    height="24"
                    viewBox="0 0 24 24"
                    width="24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M10 15.172l9.192-9.193 1.415 1.414L10 18l-6.364-6.364 1.414-1.414 4.95 4.95z" />
                  </svg>
                </li>
              </ul>
            </nav>
            <button
              class="crayons-btn crayons-btn--secondary w-100 mt-4"
              type="button"
              onClick={() => setIsNavOpen(false)}
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

Default.story = {
  name: 'MobileDrawerNavigation',
};
