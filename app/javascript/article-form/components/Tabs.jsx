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
            data-text="Edit"
            className={`crayons-tabs__item ${
              previewShowing ? '' : 'crayons-tabs__item--current'
            }`}
            onClick={(e) => {
              previewShowing && onPreview(e);
            }}
            type="button"
            aria-current={previewShowing ? null : 'page'}
          >
            Edit
          </button>
        </li>
        <li>
          <button
            data-text="Preview"
            className={`crayons-tabs__item ${
              previewShowing ? 'crayons-tabs__item--current' : ''
            }`}
            onClick={(e) => {
              !previewShowing && onPreview(e);
            }}
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
