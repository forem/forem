import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';

export const Toolbar = ({ version }) => {
  return (
    <div
      className={`crayons-article-form__toolbar ${
        version === 'v1' && 'border-t-0'
      }`}
    >
      <ImageUploader />
    </div>
  );
};

Toolbar.propTypes = {
  version: PropTypes.string.isRequired,
};

Toolbar.displayName = 'Toolbar';
