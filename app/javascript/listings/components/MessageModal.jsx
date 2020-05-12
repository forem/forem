import { h } from 'preact';
import PropTypes from 'prop-types';

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
      id="listings-message-form"
      className="listings-contact-via-connect"
      onSubmit={onSubmit}
    >
      {isCurrentUserOnListing ? (
        <p id="personal-contact-message">
          This is your active listing. Any member can contact you via this form.
        </p>
      ) : (
        <p>
          <b id="generic-contact-message">
            Contact
            {` ${listing.author.name} `}
            via DEV Connect
          </b>
        </p>
      )}
      <textarea
        value={message}
        onChange={onChangeDraftingMessage}
        id="new-message"
        rows="4"
        cols="70"
        placeholder="Enter your message here..."
      />
      <button type="submit" value="Submit" className="submit-button cta">
        SEND
      </button>
      <p>
        {isCurrentUserOnListing ? (
          <em id="personal-message-about-interactions">
            All private interactions 
            {' '}
            <b>must</b>
            {' '}
            abide by the
            {' '}
            <a href="/code-of-conduct">code of conduct</a>
          </em>
        ) : (
          <em id="generic-message-about-interactions">
            Message must be relevant and on-topic with the listing. All private
            interactions 
            {' '}
            <b>must</b>
            {' '}
            abide by the
            {' '}
            <a href="/code-of-conduct">code of conduct</a>
          </em>
        )}
      </p>
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
