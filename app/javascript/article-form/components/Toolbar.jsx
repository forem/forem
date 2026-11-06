import { h } from 'preact';
import { useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { MarkdownToolbar, Link, ButtonNew as Button } from '@crayons';
import { BREAKPOINTS, useMediaQuery } from '@components/useMediaQuery';
import HelpIcon from '@images/help.svg';
import AgentSessionIcon from '@images/agent-session.svg';

export const Toolbar = ({ version, textAreaId }) => {
  const extraSmallScreen = useMediaQuery(
    `(max-width: ${BREAKPOINTS.ExtraSmall - 1}px)`,
  );
  const smallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Medium - 1}px)`);

  useEffect(() => {
    if (!smallScreen) {
      const guideSidecar = document.getElementById('editor-guide-sidecar');
      if (guideSidecar && !guideSidecar.classList.contains('hidden')) {
        guideSidecar.classList.add('hidden');
        guideSidecar.classList.remove('editor-sidecar--open');
      }
    }
  }, [smallScreen]);

  const agentSessionElement = (
    <Link
      key="agent-session-link"
      block={extraSmallScreen}
      href="/agent_sessions/new"
      target="_blank"
      rel="noopener noreferrer"
      icon={AgentSessionIcon}
      aria-label="Upload Agent Session"
      title="Upload Agent Session"
    />
  );

  const helpElement = (
    <Button
      key="help-btn"
      onClick={() => {
        document.dispatchEvent(new Event('toggle-editor-guide'));
      }}
      icon={HelpIcon}
      aria-label="Help"
      title="Help"
    />
  );

  let primaryElements = [agentSessionElement];
  let secondaryElements = [];

  if (extraSmallScreen) {
    primaryElements = [];
    secondaryElements = [agentSessionElement, helpElement];
  } else if (smallScreen) {
    primaryElements = [agentSessionElement, helpElement];
  }

  return (
    <div
      className={`crayons-article-form__toolbar ${version === 'v1' ? 'border-t-0' : ''
        }`}
    >
      <MarkdownToolbar
        textAreaId={textAreaId}
        additionalPrimaryToolbarElements={primaryElements}
        additionalSecondaryToolbarElements={secondaryElements}
      />
    </div>
  );
};

Toolbar.propTypes = {
  version: PropTypes.string.isRequired,
  textAreaId: PropTypes.string,
};

Toolbar.displayName = 'Toolbar';
