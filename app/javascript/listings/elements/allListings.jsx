import { h } from 'preact';
import PropTypes from 'prop-types';
import SingleListing from '../singleListing';

const AllListings = ({
  listings,
  onAddTag,
  onChangeCategory,
  currentUserId,
  onOpenModal,
}) =>
  listings.map((listing) => (
    <SingleListing
      onAddTag={onAddTag}
      onChangeCategory={onChangeCategory}
      listing={listing}
      currentUserId={currentUserId}
      onOpenModal={onOpenModal}
      isOpen={false}
    />
  ));

AllListings.propTypes = {
  currentUserId: PropTypes.number,
  listing: PropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
};

AllListings.defaultProps = {
  currentUserId: null,
};

export default AllListings;
