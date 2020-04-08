import { h } from 'preact';
import { Dropdown } from '../../crayons/Dropdown';

export const OverflowNavigation = () => {
  return (
    <div>
      <button
        className="crayons-btn crayons-btn--ghost crayons-story__overflow"
        type="button"
      >
        <svg
          className="crayons-icon"
          width="24"
          height="24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fillRule="evenodd"
            clipRule="evenodd"
            d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"
          />
        </svg>
      </button>
      <Dropdown>
        <a href="/" className="crayons-link crayons-link--block">
          Subscribe
        </a>
        <a href="/" className="crayons-link crayons-link--block">
          Share on Twitter
        </a>
        <a href="/" className="crayons-link crayons-link--block">
          Share on Facebook
        </a>
        <a href="/" className="crayons-link crayons-link--block">
          Report abuse
        </a>
      </Dropdown>
    </div>
  );
};

OverflowNavigation.displayName = 'OverflowNavigation';
