import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleListing } from '../singleListing/SingleListing';
import { Modal as CrayonsModal } from '@crayons';

export const Modal = ({
  currentUserId,
  onAddTag,
  onClick,
  onChangeCategory,
  onOpenModal,
  listing,
}) => {
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
      </CrayonsModal>
    </div>
  );
};

Modal.propTypes = {
  listing: PropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onClick: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  currentUserId: PropTypes.number,
};

Modal.defaultProps = {
  currentUserId: null,
};
