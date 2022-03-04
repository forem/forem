import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { ArticleFormTitle } from './ArticleFormTitle';
import { TagInput } from './TagInput';
import { BasicEditor } from './BasicEditor';
import { EditorFormattingHelp } from './EditorFormattingHelp';
import { Modal } from '@crayons';

const renderModal = (onClose, title, selector) => {
  const helpHtml = document.getElementById(selector)?.innerHTML;

  return (
    <Modal onClose={onClose} title={title}>
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{ __html: helpHtml }}
      />
    </Modal>
  );
};

/**
 * Renders help component for given section
 * @param {object} props Component properties
 * @param {boolean} props.previewShowing Boolean to decide if to show the preview
 * @param {string} props.helpFor Section for which help is shown
 * @param {number} props.helpPosition Offset from the top of the help component
 * @param {string} props.version Version of the editor used for article
 *
 * @returns Help component for the given section
 */
export const Help = ({ previewShowing, helpFor, helpPosition, version }) => {
  const [helpSectionVisibility, setHelpSectionVisibility] = useState({
    liquidShowing: false,
    markdownShowing: false,
    frontmatterShowing: false,
  });

  const openModal = (helpSection) => {
    setHelpSectionVisibility({
      [helpSection]: true,
    });
  };

  const closeModal = (helpSection) => {
    setHelpSectionVisibility({
      [helpSection]: false,
    });
  };

  const { liquidShowing, markdownShowing, frontmatterShowing } =
    helpSectionVisibility;

  return (
    <div className="crayons-article-form__aside">
      {!previewShowing && (
        <div
          data-testid="article-form__help-section"
          className="sticky"
          style={{ top: version === 'v1' ? '56px' : helpPosition }}
        >
          {helpFor === 'article-form-title' && <ArticleFormTitle />}
          {helpFor === 'tag-input' && <TagInput />}

          {version === 'v1' && <BasicEditor openModal={openModal} />}

          {(helpFor === 'article_body_markdown' || version === 'v1') && (
            <EditorFormattingHelp openModal={openModal} />
          )}
        </div>
      )}
      {liquidShowing &&
        renderModal(
          () => closeModal('liquidShowing'),
          '🌊 Liquid Tags',
          'editor-liquid-help',
        )}

      {markdownShowing &&
        renderModal(
          () => closeModal('markdownShowing'),
          '✍️ Markdown',
          'editor-markdown-help',
        )}
      {frontmatterShowing &&
        renderModal(
          () => closeModal('frontmatterShowing'),
          'Jekyll Front Matter',
          'editor-frontmatter-help',
        )}
    </div>
  );
};

Help.defaultProps = {
  helpFor: '',
  helpPosition: 0,
};

Help.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  helpFor: PropTypes.string,
  helpPosition: PropTypes.number,
  version: PropTypes.string.isRequired,
};

Help.displayName = 'Help';
