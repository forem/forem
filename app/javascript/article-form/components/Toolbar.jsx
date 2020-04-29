import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';

export const Toolbar = ({visible}) => {
  return (
    <div
      className={`crayons-article-form__toolbar ${
        visible ? '' : 'opacity-0'
      }`}
    >
      <ImageUploader />
    </div>
  );
};

Toolbar.propTypes = {
  visible: PropTypes.bool.isRequired,
};

Toolbar.displayName = 'Toolbar';
