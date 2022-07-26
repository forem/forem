import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';
import { MarkdownToolbar, Link } from '@crayons';
import HelpIcon from '@images/help.svg';

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
        <MarkdownToolbar
          textAreaId={textAreaId}
          additionalSecondaryToolbarElements={[
            <Link
              key="help-link"
              block
              href="/p/editor_guide"
              target="_blank"
              rel="noopener noreferrer"
              icon={HelpIcon}
              aria-label="Help"
            />,
          ]}
        />
      )}
    </div>
  );
};

Toolbar.propTypes = {
  version: PropTypes.string.isRequired,
};

Toolbar.displayName = 'Toolbar';
