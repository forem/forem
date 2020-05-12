import PropTypes from 'prop-types';
import { h } from 'preact';

import Header from './Header';
import TagLinks from './TagLinks';
import AuthorInfo from './AuthorInfo';
import listingPropTypes from './listingPropTypes';

const SingleListing = ({
  listing,
  currentUserId,
  onAddTag,
  onChangeCategory,
  onOpenModal,
  isOpen,
}) => {
  const definedClass = isOpen
    ? 'single-classified-listing single-classified-listing--opened'
    : 'single-classified-listing';

  return (
    <div
      className={definedClass}
      id={`single-classified-listing-${listing.id}`}
    >
      <div className="listing-content">
        <Header
          listing={listing}
          currentUserId={currentUserId}
          onTitleClick={onOpenModal}
        />
        <div
          className="single-classified-listing-body"
          dangerouslySetInnerHTML={{ __html: listing.processed_html }} // eslint-disable-line react/no-danger
        />
        <TagLinks tags={listing.tags} onClick={onAddTag} />
        <AuthorInfo listing={listing} onCategoryClick={onChangeCategory} />
      </div>
    </div>
  );
};

SingleListing.propTypes = {
  listing: listingPropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  isOpen: PropTypes.bool.isRequired,
  currentUserId: PropTypes.number,
};

SingleListing.defaultProps = {
  currentUserId: null,
};

export default SingleListing;
