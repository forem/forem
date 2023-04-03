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
            data-text="Редагувати"
            className={`crayons-tabs__item ${
              previewShowing ? '' : 'crayons-tabs__item--current'
            }`}
            onClick={(e) => {
              previewShowing && onPreview(e);
            }}
            type="button"
            aria-current={previewShowing ? null : 'page'}
          >
            Редагувати
          </button>
        </li>
        <li>
          <button
            data-text="Попередній перегляд"
            className={`crayons-tabs__item ${
              previewShowing ? 'crayons-tabs__item--current' : ''
            }`}
            onClick={(e) => {
              !previewShowing && onPreview(e);
            }}
            type="button"
            aria-current={previewShowing ? 'page' : null}
          >
            Попередній перегляд
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
