import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Header from './Header';
import AuthorInfo from './AuthorInfo';
import listingPropTypes from './listingPropTypes';
import Endorsement from './Endorsement';
export class SingleListing extends Component {

  listingContent = (listing, currentUserId, onChangeCategory, onOpenModal, onAddTag, isOpen) => {
    const endorsements = listing.listing_endorsements.length;
    return (
      <div className="relative">
        <Header
          listing={listing}
          currentUserId={currentUserId}
          onTitleClick={onOpenModal}
          onAddTag={onAddTag}
        />
        <div
          className="mb-4"
          dangerouslySetInnerHTML={{ __html: listing.processed_html }} // eslint-disable-line react/no-danger
        />
        <AuthorInfo listing={listing} onCategoryClick={onChangeCategory} />
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
          <span>{ endorsements > 1 ?  `${endorsements} endorsements` : `${endorsements} endorsement`}</span>
        )}
      </div>
    ) : (
      ''
    )}
      </div>
    );
  };

  listingInline = (listing, currentUserId, onChangeCategory, onOpenModal, onAddTag, isOpen) => {
    return (
      <div
        className="single-listing relative crayons-card"
        id={`single-listing-${listing.id}`}
        data-testid={`single-listing-${listing.id}`}
      >
        <div className="listing-content p-4">
          {this.listingContent(
            listing,
            currentUserId,
            onChangeCategory,
            onOpenModal,
            onAddTag,
            isOpen
          )}
        </div>
      </div>
    );
  };

  listingModal = (listing, currentUserId, onChangeCategory, onOpenModal, onAddTag, isOpen) => {
    return (
      <div
        className="single-listing relative"
        id={`single-listing-${listing.id}`}
        data-testid={`single-listing-${listing.id}`}
      >
        <div className="listing-content">
          {this.listingContent(
            listing,
            currentUserId,
            onChangeCategory,
            onOpenModal,
            onAddTag,
            isOpen
          )}
        </div>
      </div>
    );
  };

  render() {
    const { listing, currentUserId, onChangeCategory, onOpenModal, isOpen, onAddTag } = this.props;
    return (
      isOpen ?
        this.listingModal(
          listing,
          currentUserId,
          onChangeCategory,
          onOpenModal,
          onAddTag,
          isOpen
        )
        :
        this.listingInline(
          listing,
          currentUserId,
          onChangeCategory,
          onOpenModal,
          onAddTag,
          isOpen
        )
    );
  }
}

SingleListing.propTypes = {
  listing: listingPropTypes.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  isOpen: PropTypes.bool.isRequired,
  currentUserId: PropTypes.number,
  onAddTag: PropTypes.func.isRequired
};

SingleListing.defaultProps = {
  currentUserId: null,
};

SingleListing.displayName = 'SingleListing';
