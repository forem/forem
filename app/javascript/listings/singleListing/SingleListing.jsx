import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Header from './Header';
import AuthorInfo from './AuthorInfo';
import listingPropTypes from './listingPropTypes';

export class SingleListing extends Component {
  listingContent = (
    listing,
    currentUserId,
    onChangeCategory,
    onOpenModal,
    onAddTag,
  ) => {
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
      </div>
    );
  };

  listingInline = (
    listing,
    currentUserId,
    onChangeCategory,
    onOpenModal,
    onAddTag,
  ) => {
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
          )}
        </div>
      </div>
    );
  };

  listingModal = (
    listing,
    currentUserId,
    onChangeCategory,
    onOpenModal,
    onAddTag,
  ) => {
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
          )}
        </div>
      </div>
    );
  };

  render() {
    const {
      listing,
      currentUserId,
      onChangeCategory,
      onOpenModal,
      isOpen,
      onAddTag,
    } = this.props;
    return isOpen
      ? this.listingModal(
          listing,
          currentUserId,
          onChangeCategory,
          onOpenModal,
          onAddTag,
        )
      : this.listingInline(
          listing,
          currentUserId,
          onChangeCategory,
          onOpenModal,
          onAddTag,
        );
  }
}

SingleListing.propTypes = {
  listing: listingPropTypes.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  isOpen: PropTypes.bool.isRequired,
  currentUserId: PropTypes.number,
  onAddTag: PropTypes.func.isRequired,
};

SingleListing.defaultProps = {
  currentUserId: null,
};

SingleListing.displayName = 'SingleListing';
