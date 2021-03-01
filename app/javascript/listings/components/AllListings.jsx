import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleListing } from '../singleListing/SingleListing';
import { NextPageButton } from './NextPageButton';

export const AllListings = ({
  listings,
  onAddTag,
  onChangeCategory,
  currentUserId,
  onOpenModal,
  showNextPageButton,
  loadNextPage,
}) => {
  return (
    <main class="crayons-layout__content" id="main-content">
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

      {showNextPageButton && <NextPageButton onClick={loadNextPage} />}
    </main>
  );
};

AllListings.propTypes = {
  currentUserId: PropTypes.number,
  listings: PropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  showNextPageButton: PropTypes.bool.isRequired,
  loadNextPage: PropTypes.func.isRequired,
};

AllListings.defaultProps = {
  currentUserId: null,
};
