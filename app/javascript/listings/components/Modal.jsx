import { h } from 'preact';
import PropTypes from 'prop-types';
import SingleListing from '../singleListing';
import MessageModal from './MessageModal';
import EndorseMessageModal from './EndorseMessageModal';

const Modal = ({
  currentUserId,
  onAddTag,
  onChangeDraftingMessage,
  onClick,
  onChangeCategory,
  onOpenModal,
  onSubmit,
  onEndorseSubmit,
  listing,
  endorseMessage,
  message,
}) => {
  const shouldRenderMessageModal = listing && listing.contact_via_connect;
  console.log(currentUserId, listing, message);
  return (
    <div className="single-listing-container">
      <div
        id="single-listing-container__inner"
        className="single-listing-container__inner"
        onClick={onClick}
        role="button"
        onKeyPress={onClick}
        tabIndex="0"
      >
        <SingleListing
          onAddTag={onAddTag}
          onChangeCategory={onChangeCategory}
          listing={listing}
          currentUserId={currentUserId}
          onOpenModal={onOpenModal}
          isOpen
        />
        {shouldRenderMessageModal && (
          <EndorseMessageModal
            onSubmit={onEndorseSubmit}
            onChangeDraftingMessage={onChangeDraftingMessage}
            endorseMessage={endorseMessage}
            listing={listing}
          />
        )}
        {shouldRenderMessageModal && (
          <MessageModal
            onSubmit={onSubmit}
            onChangeDraftingMessage={onChangeDraftingMessage}
            message={message}
            listing={listing}
          />
        )}
        <a href="/about-listings" className="single-listing-info-link">
          About DEV Listings
        </a>
        <div className="single-listing-container__spacer" />
      </div>
    </div>
  );
};

Modal.propTypes = {
  listing: PropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onChangeDraftingMessage: PropTypes.func.isRequired,
  onClick: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onEndorseSubmit: PropTypes.func.isRequired,
  currentUserId: PropTypes.number,
  endorseMessage: PropTypes.string,
  message: PropTypes.string,
};

Modal.defaultProps = {
  currentUserId: null,
};

export default Modal;
