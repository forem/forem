import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';

export const Toolbar = () => {
  return (
    <div className="crayons-article-form__toolbar">
      <ImageUploader />
    </div>
  );
};

Toolbar.propTypes = {
  visible: PropTypes.bool.isRequired,
};

Toolbar.displayName = 'Toolbar';
