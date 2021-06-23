import { h } from 'preact';
import PropTypes from 'prop-types';

export const Tabs = ({ onPreview, previewShowing }) => {
  return (
    <nav
      className="crayons-article-form__tabs crayons-tabs ml-auto"
      aria-label="View post modes"
    >
      <ul className="crayons-tabs__list">
        <li>
          <button
            className={`crayons-tabs__item ${
              previewShowing ? '' : 'crayons-tabs__item--current'
            }`}
            onClick={previewShowing && onPreview}
            type="button"
            aria-current={previewShowing ? null : 'page'}
          >
            Edit
          </button>
        </li>
        <li>
          <button
            className={`crayons-tabs__item ${
              previewShowing ? 'crayons-tabs__item--current' : ''
            }`}
            onClick={!previewShowing && onPreview}
            type="button"
            aria-current={previewShowing ? 'page' : null}
          >
            Preview
          </button>
        </li>
      </ul>
    </nav>
  );
};

Tabs.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  onPreview: PropTypes.func.isRequired,
};

Tabs.displayName = 'Tabs';
