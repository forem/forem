import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleListing } from '../singleListing/SingleListing';
import { MessageModal } from './MessageModal';
import { Modal as CrayonsModal } from '@crayons';

export const Modal = ({
  currentUserId,
  onAddTag,
  onChangeDraftingMessage,
  onClick,
  onChangeCategory,
  onOpenModal,
  onSubmit,
  listing,
  message,
}) => {
  const shouldRenderMessageModal = listing && listing.contact_via_connect;

  return (
    <div className="listings-modal" data-testid="listings-modal">
      <CrayonsModal
        onClose={onClick}
        closeOnClickOutside={true}
        title="Listing"
      >
        <div className="p-3 m:p-6 l:p-8">
          <SingleListing
            onAddTag={onAddTag}
            onChangeCategory={onChangeCategory}
            listing={listing}
            currentUserId={currentUserId}
            onOpenModal={onOpenModal}
            isOpen
          />
        </div>
        {shouldRenderMessageModal && (
          <div className="bg-base-10 p-3 m:p-6 l:p-8">
            <MessageModal
              onSubmit={onSubmit}
              onChangeDraftingMessage={onChangeDraftingMessage}
              message={message}
              listing={listing}
            />
          </div>
        )}
      </CrayonsModal>
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
  currentUserId: PropTypes.number,
  message: PropTypes.string.isRequired,
};

Modal.defaultProps = {
  currentUserId: null,
};
