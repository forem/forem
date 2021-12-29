import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

function linksToMarkdownForm(imageLinks) {
  return imageLinks
    .map((imageLink) => `![Image description](${imageLink})`)
    .join('\n');
}

const CopyIcon = () => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    aria-labelledby="fc5f15add1e114844f5e"
  >
    <title id="fc5f15add1e114844f5e">Copy Markdown for image</title>
    <path d="M7 6V3a1 1 0 011-1h12a1 1 0 011 1v14a1 1 0 01-1 1h-3v3c0 .552-.45 1-1.007 1H4.007A1 1 0 013 21l.003-14c0-.552.45-1 1.007-1H7zm2 0h8v10h2V4H9v2zm-2 5v2h6v-2H7zm0 4v2h6v-2H7z" />
  </svg>
);

CopyIcon.displayName = 'CopyIcon';

export const ClipboardButton = ({
  onCopy,
  imageUrls,
  showCopyMessage = false,
}) => (
  <clipboard-copy
    onClick={onCopy}
    for="image-markdown-copy-link-input"
    aria-live="polite"
    className="flex items-center flex-1"
    aria-controls="image-markdown-copy-link-announcer"
  >
    <input
      data-testid="markdown-copy-link"
      type="text"
      className="crayons-textfield mr-2"
      id="image-markdown-copy-link-input"
      readOnly="true"
      value={linksToMarkdownForm(imageUrls)}
    />
    <Button
      className="spec__image-markdown-copy whitespace-nowrap fw-normal"
      variant="ghost"
      contentType="icon-left"
      icon={CopyIcon}
    >
      {showCopyMessage ? 'Copied!' : 'Copy...'}
    </Button>
  </clipboard-copy>
);

ClipboardButton.displayName = 'ClipboardButton';

ClipboardButton.propTypes = {
  onCopy: PropTypes.func.isRequired,
  imageUrls: PropTypes.arrayOf(PropTypes.string).isRequired,
  showCopyMessage: PropTypes.bool.isRequired,
};
