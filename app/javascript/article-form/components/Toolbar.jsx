import { h } from 'preact';
import PropTypes from 'prop-types';
import { ImageUploader } from './ImageUploader';
import { MarkdownToolbar, Link } from '@crayons';
import HelpIcon from '@images/help.svg';
import AgentSessionIcon from '@images/agent-session.svg';

export const Toolbar = ({ version, textAreaId }) => {
  return (
    <div
      className={`crayons-article-form__toolbar ${version === 'v1' ? 'border-t-0' : ''
        }`}
    >
      <MarkdownToolbar
        textAreaId={textAreaId}
        additionalPrimaryToolbarElements={[
          <Link
            key="agent-session-link"
            href="/agent_sessions/new"
            target="_blank"
            rel="noopener noreferrer"
            icon={AgentSessionIcon}
            aria-label="Upload Agent Session"
            title="Upload Agent Session"
          />,
        ]}
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
    </div>
  );
};

Toolbar.propTypes = {
  version: PropTypes.string.isRequired,
};

Toolbar.displayName = 'Toolbar';
