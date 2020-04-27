import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const Tabs = ({ onPreview, previewShowing }) => {
  return (
    <div className="crayons-article-form__tabs ml-auto">
      <Button
        variant="ghost"
        className={!previewShowing && 'current'}
        onClick={previewShowing && onPreview}
      >
        Edit
      </Button>
      <Button
        variant="ghost"
        className={previewShowing && 'current'}
        onClick={!previewShowing && onPreview}
      >
        Preview
      </Button>
    </div>
  );
};


Tabs.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  onPreview: PropTypes.func.isRequired,
};

Tabs.displayName = 'Tabs';
