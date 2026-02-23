import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';
import { MarkdownToolbar, Link } from '@crayons';
import HelpIcon from '@images/help.svg';

export const Toolbar = ({ version, textAreaId }) => {
  return (
    <div
      className={`crayons-article-form__toolbar ${version === 'v1' ? 'border-t-0' : ''
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
              href="#"
              onClick={(e) => {
                e.preventDefault();
                document.dispatchEvent(new Event('toggle-editor-guide'));
              }}
              icon={HelpIcon}
              aria-label="Help"
              title="Help"
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
