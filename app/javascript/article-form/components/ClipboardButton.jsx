import { h } from 'preact';
import PropTypes from 'prop-types';
import { ButtonNew as Button } from '@crayons';
import CopyIcon from '@images/copy.svg';

function linksToMarkdownForm(imageLinks) {
  return imageLinks
    .map((imageLink) => `![Image description](${imageLink})`)
    .join('\n');
}

export const ClipboardButton = ({
  onCopy,
  imageUrls,
  showCopyMessage = false,
}) => (
  <div aria-live="polite" className="flex items-center flex-1">
    <input
      data-testid="markdown-copy-link"
      type="text"
      className="crayons-textfield mr-2"
      id="image-markdown-copy-link-input"
      readOnly="true"
      value={linksToMarkdownForm(imageUrls)}
    />
    <Button
      onClick={onCopy}
      className="spec__image-markdown-copy whitespace-nowrap fw-normal"
      icon={CopyIcon}
      title="Copy"
    >
      {showCopyMessage ? 'Copied!' : 'Copy...'}
    </Button>
  </div>
);

ClipboardButton.displayName = 'ClipboardButton';

ClipboardButton.propTypes = {
  onCopy: PropTypes.func.isRequired,
  imageUrls: PropTypes.arrayOf(PropTypes.string).isRequired,
  showCopyMessage: PropTypes.bool.isRequired,
};
