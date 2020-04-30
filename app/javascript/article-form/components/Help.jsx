import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Modal } from './Modal';

export class Help extends Component {
  constructor(props) {
    super(props);
    this.state = {
      liquidHelpHTML: document.getElementById('editor-liquid-help').innerHTML,
      markdownHelpHTML: document.getElementById('editor-markdown-help')
        .innerHTML,
      frontmatterHelpHTML: document.getElementById('editor-frontmatter-help')
        .innerHTML,
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

  toggleLiquid = (e) => {
    const { liquidShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({
        liquidShowing: !liquidShowing,
      }),
    });
  };

  toggleMarkdown = (e) => {
    const { markdownShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({
        markdownShowing: !markdownShowing,
      }),
    });
  };

  toggleFrontmatter = (e) => {
    const { frontmatterShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({
        frontmatterShowing: !frontmatterShowing,
      }),
    });
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
      <div className="crayons-layout__aside">
        {!previewShowing && (
          <div
            className="crayons-article-form__tips"
            style={{ top: version === 'v1' ? '56px' : helpPosition }}
          >
            {helpFor === 'article-form-title' && (
              <div>
                <h4 className="mb-2 fs-l">How to write a good post title?</h4>
                <ul className="list-disc pl-6 color-base-70">
                  <li>
                    Think of post title as super short description. Like an
                    overview of the actual post in one short sentence...
                  </li>
                  <li>Be specific :)</li>
                </ul>
              </div>
            )}

            {helpFor === 'tag-input' && (
              <div>
                <h4 className="mb-2 fs-l">Use appropriate tags</h4>
                <ul className="list-disc pl-6 color-base-70">
                  <li>Tags will help the right people find your post.</li>
                  <li>
                    Think of tags as topics or categories that you could
                    identify your post with.
                  </li>
                  <li>
                    Limit number of tags to maximum 4 and try to use existing
                    tags.
                  </li>
                  <li>
                    Remember that some tags have special posting guidelines.
                  </li>
                </ul>
              </div>
            )}

            {(helpFor === 'article_body_markdown' || version === 'v1') && (
              <div>
                {version === 'v1' && (
                  <div className="crayons-card crayons-card--secondary p-4 mb-6">
                    You are currently using basic markdown editor that uses
                    {' '}
                    <a href="#frontmatter" onClick={this.toggleFrontmatter}>
                      Jekyll front matter
                    </a>
                    . You can also use 
                    {' '}
                    <em>rich+markdown</em>
                    {' '}
                    editor you can
                    find in 
                    {' '}
                    <a href="/settings/ux">UX settings</a>
                    .
                  </div>
                )}

                <h4 className="mb-2 fs-l">How to use editor?</h4>
                <ul className="list-disc pl-6 color-base-70">
                  <li>
                    Use
                    {' '}
                    <a href="#markdown" onClick={this.toggleMarkdown}>
                      Markdown
                    </a>
                    {' '}
                    to write and format posts.
                  </li>
                  <li>
                    Most of the time, you can write inline HTML directly into
                    your posts.
                  </li>
                  <li>
                    You can use
                    {' '}
                    <a href="#liquid" onClick={this.toggleLiquid}>
                      Liquid tags
                    </a>
                    {' '}
                    to add rich content such as tweets and videos.
                  </li>
                </ul>
              </div>
            )}
          </div>
        )}

        {liquidShowing && (
          <Modal onToggleHelp={this.toggleLiquid} title="🌊 Liquid Tags">
            {liquidHelpHTML}
          </Modal>
        )}

        {markdownShowing && (
          <Modal onToggleHelp={this.toggleMarkdown} title="✍️ Markdown">
            {markdownHelpHTML}
          </Modal>
        )}

        {frontmatterShowing && (
          <Modal
            onToggleHelp={this.toggleFrontmatter}
            title="Jekyll Front Matter"
          >
            {frontmatterHelpHTML}
          </Modal>
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
