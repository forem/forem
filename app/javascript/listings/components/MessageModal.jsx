import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

const MessageModal = ({
  currentUserId,
  message,
  listing,
  onSubmit,
  onChangeDraftingMessage,
}) => {
  const isCurrentUserOnListing = listing.user_id === currentUserId;

  return (
    <form
      data-testid="listings-message-modal"
      id="listings-message-form"
      onSubmit={onSubmit}
    >
      <header className="mb-4">
        <h2 className="fs-xl fw-bold lh-tight">Interested?</h2>
        {isCurrentUserOnListing ? (
          <p className="color-base-70">
            This is your active listing. Any member can contact you via this
            form.
          </p>
        ) : (
          <p className="color-base-70">Message {` ${listing.author.name} `}</p>
        )}
      </header>
      <textarea
        value={message}
        onChange={onChangeDraftingMessage}
        data-testid="listing-new-message"
        id="new-message"
        className="crayons-textfield mb-0"
        placeholder="Enter your message here..."
        aria-label="Message"
      />
      <p className="mb-4 fs-s color-base-60">
        {isCurrentUserOnListing &&
          'Message must be relevant and on-topic with the listing.'}
        All private interactions <b>must</b> abide by the{' '}
        <a href="/code-of-conduct" className="crayons-link crayons-link--brand">
          Code of Conduct
        </a>
        .
      </p>
      <div className="flex">
        <Button
          variant="primary"
          className="mr-2"
          tagName="button"
          type="submit"
        >
          Send
        </Button>
      </div>
    </form>
  );
};

MessageModal.propTypes = {
  currentUserId: PropTypes.number.isRequired,
  message: PropTypes.string.isRequired,
  listing: PropTypes.shape({
    author: PropTypes.shape({
      name: PropTypes.string.isRequired,
    }).isRequired,
    user_id: PropTypes.number.isRequired,
  }).isRequired,
  onSubmit: PropTypes.func.isRequired,
  onChangeDraftingMessage: PropTypes.func.isRequired,
};

export default MessageModal;
