import { h, Fragment } from 'preact';
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
    <Fragment>
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
    </Fragment>
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
