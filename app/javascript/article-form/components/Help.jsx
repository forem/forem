import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';
import { Modal } from './Modal';

export class Help extends Component {
  constructor(props) {
    super(props);
    this.state = {
      liquidHelpHTML: document.getElementById('editor-liquid-help').innerHTML,
      markdownHelpHTML: document.getElementById('editor-markdown-help').innerHTML,
    };
  };

  render () {
    const {
      previewShowing,
      onHelpMarkdown,
      onHelpLiquid,
      toggleHelp,
      modalShowing,
    } = this.props;

    const { liquidHelpHTML, markdownHelpHTML } = this.state;

    return (
      <div className="crayons-layout--aside">
        {!previewShowing && (
          <div className="pt-10">
            <h4 className="mb-2 fs-l">How to write a good post title?</h4>
            <ul className="list-disc pl-6 color-base-70">
              <li>
                Think of post title as super short description. Like an overview
                of the actual post in one short sentence...
              </li>
              <li>Be specific :)</li>
              <li>
                <Button variant="secondary" onClick={toggleHelp}>
                  Help Markdown
                </Button>
                <Button variant="secondary" onClick={toggleHelp}>
                  Help Liquid
                </Button>
              </li>
            </ul>
          </div>
        )}

        {modalShowing && (
          <Modal onToggleHelp={toggleHelp} title="Markdown Help">
            {markdownHelpHTML}
            {liquidHelpHTML}
          </Modal>
        )}
      </div>
    );
  }
};

Help.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  onHelpMarkdown: PropTypes.func.isRequired,
  onHelpLiquid: PropTypes.func.isRequired,
  toggleHelp: PropTypes.func.isRequired,
  modalShowing: PropTypes.bool.isRequired,
};

Help.displayName = 'Help';
