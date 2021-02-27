import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import ArticleFormTitle from './ArticleFormTitle';
import TagInput from './TagInput';
import BasicEditor from './BasicEditor';
import EditorFormattingHelp from './EditorFormattingHelp';
import { Modal } from '@crayons';

const renderModal = (onClose, title, helpHtml) => {
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
    liquidHelpHTML:
      document.getElementById('editor-liquid-help') &&
      document.getElementById('editor-liquid-help').innerHTML,
    markdownHelpHTML:
      document.getElementById('editor-markdown-help') &&
      document.getElementById('editor-markdown-help').innerHTML,
    frontmatterHelpHTML:
      document.getElementById('editor-frontmatter-help') &&
      document.getElementById('editor-frontmatter-help').innerHTML,
    liquidShowing: false,
    markdownShowing: false,
    frontmatterShowing: false,
  });

  const toggleModal = (varShowing) => (e) => {
    e.preventDefault();
    setState((prevState) => ({
      [varShowing]: !prevState[varShowing],
    }));
  };

  const {
    liquidHelpHTML,
    markdownHelpHTML,
    frontmatterHelpHTML,
    liquidShowing,
    markdownShowing,
    frontmatterShowing,
  } = state;

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

          {version === 'v1' && <BasicEditor toggleModal={toggleModal} />}

          {(helpFor === 'article_body_markdown' || version === 'v1') && (
            <EditorFormattingHelp toggleModal={toggleModal} />
          )}
        </div>
      )}

      {liquidShowing &&
        renderModal(
          toggleModal('liquidShowing'),
          '🌊 Liquid Tags',
          liquidHelpHTML,
        )}

      {markdownShowing &&
        renderModal(
          toggleModal('markdownShowing'),
          '✍️ Markdown',
          markdownHelpHTML,
        )}

      {frontmatterShowing &&
        renderModal(
          toggleModal('frontmatterShowing'),
          'Jekyll Front Matter',
          frontmatterHelpHTML,
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
