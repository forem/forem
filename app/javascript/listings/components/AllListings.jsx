import { h } from 'preact';
import PropTypes from 'prop-types';
import SingleListing from '../singleListing';

const AllListings = ({
  listings,
  onAddTag,
  onChangeCategory,
  currentUserId,
  onOpenModal,
}) => {
  return (
    <div className="listings-columns" id="listings-results">
      {listings.map((listing) => (
        <SingleListing
          onAddTag={onAddTag}
          onChangeCategory={onChangeCategory}
          listing={listing}
          currentUserId={currentUserId}
          onOpenModal={onOpenModal}
          isOpen={false}
        />
      ))}
    </div>
  );
};

AllListings.propTypes = {
  currentUserId: PropTypes.number,
  listings: PropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
};

AllListings.defaultProps = {
  currentUserId: null,
};

export default AllListings;
