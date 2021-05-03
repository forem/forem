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

export const Help = ({ previewShowing, helpFor, helpPosition, version }) => {
  const [state, setState] = useState({
    liquidShowing: false,
    markdownShowing: false,
    frontmatterShowing: false,
  });

  const openModal = (helpSection) => {
    setState({
      [helpSection]: true,
    });
  };

  const closeModal = (helpSection) => {
    setState({
      [helpSection]: false,
    });
  };

  const { liquidShowing, markdownShowing, frontmatterShowing } = state;

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

Help.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  helpFor: PropTypes.string.isRequired,
  helpPosition: PropTypes.string.isRequired,
  version: PropTypes.string.isRequired,
};

Help.displayName = 'Help';
