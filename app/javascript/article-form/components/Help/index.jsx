import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import ArticleFormTitle from './ArticleFormTitle';
import TagInput from './TagInput';
import BasicEditor from './BasicEditor';
import Format from './Format';
import { Modal } from '@crayons';

export class Help extends Component {
  constructor(props) {
    super(props);
    this.state = {
      liquidHelpHTML:
        document.getElementById('editor-liquid-help') &&
        document.getElementById('editor-liquid-help').innerHTML,
      markdownHelpHTML:
        document.getElementById('editor-markdown-help') &&
        document.getElementById('editor-markdown-help').innerHTML,
      frontmatterHelpHTML:
        document.getElementById('editor-frontmatter-help') &&
        document.getElementById('editor-frontmatter-help').innerHTML,
    };
  }

  setCommonProps = ({
    liquidShowing = false,
    markdownShowing = false,
    frontmatterShowing = false,
  }) => {
    return {
      liquidShowing,
      markdownShowing,
      frontmatterShowing,
    };
  };

  toggleModal = (varShowing) => (e) => {
    e.preventDefault();
    this.setState((prevState) => ({
      ...this.setCommonProps({
        [varShowing]: !prevState[varShowing],
      }),
    }));
  };

  renderModal = (onClose, title, helpHtml) => {
    return (
      <Modal onClose={onClose} title={title}>
        <div
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{ __html: helpHtml }}
        />
      </Modal>
    );
  };

  render() {
    const { previewShowing, helpFor, helpPosition, version } = this.props;

    const {
      liquidHelpHTML,
      markdownHelpHTML,
      frontmatterHelpHTML,
      liquidShowing,
      markdownShowing,
      frontmatterShowing,
    } = this.state;

    return (
      <div className="crayons-article-form__aside">
        {!previewShowing && (
          <div
            data-testid="article-form__help-section"
            className="sticky"
            style={{ top: version === 'v1' ? '56px' : helpPosition }}
          >
            <ArticleFormTitle show={helpFor === 'article-form-title'} />
            <TagInput show={helpFor === 'tag-input'} />
            <BasicEditor
              show={version === 'v1'}
              toggleModal={this.toggleModal}
            />
            <Format
              show={helpFor === 'article_body_markdown' || version === 'v1'}
              toggleModal={this.toggleModal}
            />
            }
          </div>
        )}

        {liquidShowing &&
          this.renderModal(
            this.toggleModal('liquidShowing'),
            '🌊 Liquid Tags',
            liquidHelpHTML,
          )}

        {markdownShowing &&
          this.renderModal(
            this.toggleModal('markdownShowing'),
            '✍️ Markdown',
            markdownHelpHTML,
          )}

        {frontmatterShowing &&
          this.renderModal(
            this.toggleModal('frontmatterShowing'),
            'Jekyll Front Matter',
            frontmatterHelpHTML,
          )}
      </div>
    );
  }
}

Help.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  helpFor: PropTypes.string.isRequired,
  helpPosition: PropTypes.string.isRequired,
  version: PropTypes.string.isRequired,
};

Help.displayName = 'Help';
