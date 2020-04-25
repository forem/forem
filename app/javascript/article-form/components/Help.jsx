import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const Help = ({ previewShowing, onHelpMarkdown, onHelpLiquid }) => {
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
              <Button variant="secondary" onClick={onHelpMarkdown}>
                Help Markdown
              </Button>
              <Button variant="secondary" onClick={onHelpLiquid}>
                Help Liquid
              </Button>
            </li>
          </ul>
        </div>
      )}
    </div>
  );
};

Help.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  onHelpMarkdown: PropTypes.func.isRequired,
  onHelpLiquid: PropTypes.func.isRequired,
};


Help.displayName = 'Help';
