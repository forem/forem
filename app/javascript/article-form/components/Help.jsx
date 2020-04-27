import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Modal } from './Modal';

export class Help extends Component {
  constructor(props) {
    super(props);
    this.state = {
      liquidHelpHTML: document.getElementById('editor-liquid-help').innerHTML,
      markdownHelpHTML: document.getElementById('editor-markdown-help').innerHTML,
    };
  };

  setCommonProps = ({
    liquidShowing = false,
    markdownShowing = false,
  }) => {
    return {
      liquidShowing,
      markdownShowing,
    };
  };

  toggleLiquid = e => {
    const { liquidShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({ 
        liquidShowing: !liquidShowing,
      }),
    });
  };

  toggleMarkdown = e => {
    const { markdownShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({
        markdownShowing: !markdownShowing,
      }),
    });
  };

  render () {
    const {
      previewShowing,
    } = this.props;

    const { liquidHelpHTML, markdownHelpHTML, liquidShowing, markdownShowing } = this.state;

    return (
      <div className="crayons-layout--aside">
        {!previewShowing && (
          <div className="pt-10">
            <h4 className="mb-2 fs-l">How to write a good post title?</h4>
            <ul className="list-disc pl-6 color-base-70 hidden">
              <li>
                Think of post title as super short description. Like an overview
                of the actual post in one short sentence...
              </li>
              <li>Be specific :)</li>
            </ul>

            <ul className="list-disc pl-6 color-base-70 hidden">
              <li>Tags will help the right people find your post.</li>
              <li>
                Think of tags as topics or categories that you could identify
                your post with.
              </li>
              <li>
                Limit number of tags to maximum 4 and try to use existing tags.
              </li>
              <li>Remember that some tags have special posting guidelines.</li>
            </ul>

            <ul className="list-disc pl-6 color-base-70">
              <li>
                Use
                {' '}
                <a href="#markdown" onClick={this.toggleMarkdown}>
                  Markdown
                </a>
                {' '}
                markdown to write and format posts.
              </li>
              <li>
                Most of the time, you can write inline HTML directly into your
                posts.
              </li>
              <li>
                You can use
                {' '}
                <a href="#liquid" onClick={this.toggleLiquid}>
                  Liquid tags
                </a>
                {' '}
                to make add rich content such as tweets and videos.
              </li>
            </ul>
          </div>
        )}

        {liquidShowing && (
          <Modal onToggleHelp={this.toggleLiquid} title="🌊 Liquid Tags">
            {liquidHelpHTML}
          </Modal>
        )}

        {markdownShowing && (
          <Modal onToggleHelp={this.toggleMarkdown} title="✍️Markdown">
            {markdownHelpHTML}
          </Modal>
        )}
      </div>
    );
  }
};

Help.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
};

Help.displayName = 'Help';
