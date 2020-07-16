import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Header from './Header';
import AuthorInfo from './AuthorInfo';
import listingPropTypes from './listingPropTypes';

export class SingleListing extends Component {

  listingContent = (listing, currentUserId, onChangeCategory, onOpenModal) => {
    return (
      <div className="relative">
        <Header
          listing={listing}
          currentUserId={currentUserId}
          onTitleClick={onOpenModal}
        />
        <div
          className="mb-4"
          dangerouslySetInnerHTML={{ __html: listing.processed_html }} // eslint-disable-line react/no-danger
        />
        <AuthorInfo listing={listing} onCategoryClick={onChangeCategory} />
      </div>
    );
  };

  listingInline = (listing, currentUserId, onChangeCategory, onOpenModal) => {
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
          )}
        </div>
      </div>
    );
  };

  listingModal = (listing, currentUserId, onChangeCategory, onOpenModal) => {
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
          )}
        </div>
      </div>
    );
  };

  render() {
    const { listing, currentUserId, onChangeCategory, onOpenModal, isOpen } = this.props;
    return (
      isOpen ?
        this.listingModal(
          listing,
          currentUserId,
          onChangeCategory,
          onOpenModal
        )
        :
        this.listingInline(
          listing,
          currentUserId,
          onChangeCategory,
          onOpenModal
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
};

SingleListing.defaultProps = {
  currentUserId: null,
};

SingleListing.displayName = 'SingleListing';
