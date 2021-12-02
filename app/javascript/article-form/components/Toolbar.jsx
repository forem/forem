import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';
import { MarkdownToolbar } from '@crayons/MarkdownToolbar';

export const Toolbar = ({ version, textAreaId }) => {
  return (
    <div
      className={`crayons-article-form__toolbar ${
        version === 'v1' ? 'border-t-0' : ''
      }`}
    >
      {version === 'v1' ? (
        <ImageUploader editorVersion={version} />
      ) : (
        <MarkdownToolbar textAreaId={textAreaId} />
      )}
    </div>
  );
};

Toolbar.propTypes = {
  version: PropTypes.string.isRequired,
};

Toolbar.displayName = 'Toolbar';
