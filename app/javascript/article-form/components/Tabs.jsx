import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '../../i18n/l10n';

export const Tabs = ({ onPreview, previewShowing }) => {
  return (
    <nav
      className="crayons-article-form__tabs crayons-tabs ml-auto"
      aria-label={i18next.t('editor.tabs.aria_label')}
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
            {i18next.t('editor.tabs.edit')}
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
            {i18next.t('editor.tabs.preview')}
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
