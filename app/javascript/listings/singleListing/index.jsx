import PropTypes from 'prop-types';
import { h } from 'preact';

import Header from './Header';
import TagLinks from './TagLinks';
import AuthorInfo from './AuthorInfo';
import listingPropTypes from './listingPropTypes';
import Endorsement from './Endorsement';

const SingleListing = ({
  listing,
  currentUserId,
  onAddTag,
  onChangeCategory,
  onOpenModal,
  isOpen,
}) => {
  const definedClass = isOpen
    ? 'single-listing single-listing--opened'
    : 'single-listing';

  return (
    <div
      className={definedClass}
      id={`single-listing-${listing.id}`}
      data-testid={`single-listing-${listing.id}`}
    >
      <div className="listing-content">
        <Header
          listing={listing}
          currentUserId={currentUserId}
          onTitleClick={onOpenModal}
        />
        <div
          className="single-listing-body"
          dangerouslySetInnerHTML={{ __html: listing.processed_html }} // eslint-disable-line react/no-danger
        />
        <TagLinks tags={listing.tags} onClick={onAddTag} />
        <AuthorInfo listing={listing} onCategoryClick={onChangeCategory} />
      </div>
      {listing.listing_endorsements.length ? (
        <div className="endorsement-comp">
          <span>
            {listing.listing_endorsements.map((endorsement, idx) => {
              return (
                endorsement.approved && (
                  <Endorsement
                    avatar={endorsement.author_profile_image_90}
                    content={endorsement.content}
                    key={`end-${idx}`}
                    isOpen={isOpen}
                  />
                )
              );
            })}
          </span>
          {!isOpen && (
            <span>{`${listing.listing_endorsements.length} endorsement`}</span>
          )}
        </div>
      ) : (
        ''
      )}
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
