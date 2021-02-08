import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleListing } from '../singleListing/SingleListing';
import { MessageModal } from './MessageModal';
import { Button } from '@crayons';

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

  const Icon = () => (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      className="crayons-icon pointer-events-none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
    </svg>
  );

  // TODO: Why are we not using the crayons modal component and instead recreating it here?
  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="listing modal"
      id="single-listing-container__inner"
      className="single-listing-container__inner crayons-modal__box"
    >
      <div className="crayons-modal__box__header flex s:hidden">
        <Button
          type="button"
          id="close-listing-modal"
          tagName="button"
          contentType="icon"
          variant="ghost"
          className="ml-auto"
          icon={Icon}
          onClick={onClick}
          aria-label="Close listing"
        />
      </div>
      <div className="crayons-modal__box__body p-0">
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
  currentUserId: PropTypes.number,
  message: PropTypes.string.isRequired,
};

Modal.defaultProps = {
  currentUserId: null,
};
