import { h } from 'preact';
import PropTypes from 'prop-types';

export const Tabs = ({ onPreview, previewShowing }) => {
  return (
    <div className="crayons-article-form__tabs crayons-tabs ml-auto">
      <button
        className={`crayons-tabs__item ${
          !previewShowing && 'crayons-tabs__item--current'
        }`}
        onClick={previewShowing && onPreview}
        type="button"
      >
        Edit
      </button>
      <button
        className={`crayons-tabs__item ${
          previewShowing && 'crayons-tabs__item--current'
        }`}
        onClick={!previewShowing && onPreview}
        type="button"
      >
        Preview
      </button>
    </div>
  );
};

Tabs.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  onPreview: PropTypes.func.isRequired,
};

Tabs.displayName = 'Tabs';
