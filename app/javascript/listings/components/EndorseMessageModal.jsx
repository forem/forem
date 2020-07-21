import { h } from 'preact';
import PropTypes from 'prop-types';

const EndorseMessageModal = ({ currentUserId, message, listing, onSubmit }) => {
  const isCurrentUserOnListing = listing.user_id === currentUserId;
  console.log(isCurrentUserOnListing);
  return (
    <form
      data-testid="listings-endorse-message-modal"
      id="listings-endorse-message-form"
      className="listings-contact-via-connect"
      onSubmit={onSubmit}
    >
      <textarea
        value={message}
        data-testid="listing-endorse-new-message"
        id="new-endorse-message"
        rows="4"
        cols="70"
        placeholder="Endorse this listing here"
      />
      <button type="submit" value="Endorse" className="submit-button cta">
        ENDORSE
      </button>
    </form>
  );
};

EndorseMessageModal.propTypes = {
  currentUserId: PropTypes.number.isRequired,
  message: PropTypes.string.isRequired,
  listing: PropTypes.shape({
    author: PropTypes.shape({
      name: PropTypes.string.isRequired,
    }).isRequired,
    user_id: PropTypes.number.isRequired,
  }).isRequired,
  onSubmit: PropTypes.func.isRequired,
};

export default EndorseMessageModal;
