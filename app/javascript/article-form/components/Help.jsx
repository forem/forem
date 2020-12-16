import { h, Component } from 'preact';
import PropTypes from 'prop-types';
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

  renderArticleFormTitleHelp = () => {
    return (
      <div
        data-testid="title-help"
        className="crayons-article-form__help crayons-article-form__help--title"
      >
        <h4 className="mb-2 fs-l">Writing a Great Post Title</h4>
        <ul className="list-disc pl-6 color-base-70">
          <li>
            Think of your post title as a super short (but compelling!)
            description — like an overview of the actual post in one short
            sentence.
          </li>
          <li>
            Use keywords where appropriate to help ensure people can find your
            post by search.
          </li>
        </ul>
      </div>
    );
  };

  renderTagInputHelp = () => {
    return (
      <div
        data-testid="basic-tag-input-help"
        className="crayons-article-form__help crayons-article-form__help--tags"
      >
        <h4 className="mb-2 fs-l">Tagging Guidelines</h4>
        <ul className="list-disc pl-6 color-base-70">
          <li>Tags help people find your post.</li>
          <li>
            Think of tags as the topics or categories that best describe your
            post.
          </li>
          <li>
            Add up to four comma-separated tags per post. Combine tags to reach
            the appropriate subcommunities.
          </li>
          <li>Use existing tags whenever possible.</li>
          <li>
            Some tags, such as “help” or “healthydebate”, have special posting
            guidelines.
          </li>
        </ul>
      </div>
    );
  };

  renderBasicEditorHelp = () => {
    return (
      <div
        data-testid="basic-editor-help"
        className="crayons-card crayons-card--secondary p-4 mb-6"
      >
        You are currently using the basic markdown editor that uses{' '}
        <a href="#frontmatter" onClick={this.toggleModal('frontmatterShowing')}>
          Jekyll front matter
        </a>
        . You can also use the <em>rich+markdown</em> editor you can find in{' '}
        <a href="/settings/customization">
          UX settings
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            className="crayons-icon"
            xmlns="http://www.w3.org/2000/svg"
            role="img"
            aria-labelledby="c038a36b2512ed25db907e179ab45cfc"
          >
            <title id="c038a36b2512ed25db907e179ab45cfc">
              Open UX settings
            </title>
            <path d="M10.667 8v1.333H7.333v7.334h7.334v-3.334H16v4a.666.666 0 01-.667.667H6.667A.666.666 0 016 17.333V8.667A.667.667 0 016.667 8h4zM18 6v5.333h-1.333V8.275l-5.196 5.196-.942-.942 5.194-5.196h-3.056V6H18z" />
          </svg>
        </a>
        .
      </div>
    );
  };

  renderFormatHelp = () => {
    return (
      <div
        data-testid="format-help"
        className="crayons-article-form__help crayons-article-form__help--body"
      >
        <h4 className="mb-2 fs-l">Editor Basics</h4>
        <ul className="list-disc pl-6 color-base-70">
          <li>
            Use{' '}
            <a href="#markdown" onClick={this.toggleModal('markdownShowing')}>
              Markdown
            </a>{' '}
            to write and format posts.
            <details className="fs-s my-1">
              <summary class="cursor-pointer">Commonly used syntax</summary>
              <table className="crayons-card crayons-card--secondary crayons-table crayons-table--compact w-100 mt-2 mb-4 lh-tight">
                <tbody>
                  <tr>
                    <td className="ff-monospace">
                      # Header
                      <br />
                      ...
                      <br />
                      ###### Header
                    </td>
                    <td>
                      H1 Header
                      <br />
                      ...
                      <br />
                      H6 Header
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">*italics* or _italics_</td>
                    <td>
                      <em>italics</em>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">**bold**</td>
                    <td>
                      <strong>bold</strong>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">[Link](https://...)</td>
                    <td>
                      <a href="https://forem.com">Link</a>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">
                      * item 1<br />* item 2
                    </td>
                    <td>
                      <ul class="list-disc ml-5">
                        <li>item 1</li>
                        <li>item 2</li>
                      </ul>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">
                      1. item 1<br />
                      2. item 2
                    </td>
                    <td>
                      <ul class="list-decimal ml-5">
                        <li>item 1</li>
                        <li>item 2</li>
                      </ul>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">&gt; quoted text</td>
                    <td>
                      <span className="pl-2 border-0 border-solid border-l-4 border-base-50">
                        quoted text
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">`inline code`</td>
                    <td>
                      <code>inline code</code>
                    </td>
                  </tr>
                  <tr>
                    <td className="ff-monospace">
                      <span class="fs-xs">```</span>
                      <br />
                      code block
                      <br />
                      <span class="fs-xs">```</span>
                    </td>
                    <td>
                      <div class="highlight p-2 overflow-hidden">
                        <code>code block</code>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </details>
          </li>
          <li>
            You can use{' '}
            <a href="#liquid" onClick={this.toggleModal('liquidShowing')}>
              Liquid tags
            </a>{' '}
            to add rich content such as Tweets, YouTube videos, etc.
          </li>
          <li>
            In addition to images for the post's content, you can also drag and
            drop a cover image
          </li>
        </ul>
      </div>
    );
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
            {helpFor === 'article-form-title' &&
              this.renderArticleFormTitleHelp()}
            {helpFor === 'tag-input' && this.renderTagInputHelp()}
            {version === 'v1' && this.renderBasicEditorHelp()}
            {(helpFor === 'article_body_markdown' || version === 'v1') &&
              this.renderFormatHelp()}
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
