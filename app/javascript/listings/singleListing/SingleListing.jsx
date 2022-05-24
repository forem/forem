import { h } from 'preact';
import PropTypes from 'prop-types';

import { Header } from './Header';
import { AuthorInfo } from './AuthorInfo';
import { listingPropTypes } from './listingPropTypes';

export const SingleListing = ({ isOpen, ...props }) => {
  const listingContent = ({
    listing,
    currentUserId,
    onChangeCategory,
    onOpenModal,
    onAddTag,
    isModal = false,
  }) => {
    return (
      <div className="relative">
        <Header
          listing={listing}
          currentUserId={currentUserId}
          onTitleClick={onOpenModal}
          onAddTag={onAddTag}
          isModal={isModal}
        />
        <div
          className="mb-4"
          dangerouslySetInnerHTML={{ __html: listing.processed_html }} // eslint-disable-line react/no-danger
        />
        <AuthorInfo listing={listing} onCategoryClick={onChangeCategory} />
      </div>
    );
  };

  const listingInline = (props) => {
    const { listing } = props;
    return (
      <div
        className="single-listing relative crayons-card"
        id={`single-listing-${listing.id}`}
        data-testid={`single-listing-${listing.id}`}
      >
        <div className="listing-content p-4">{listingContent(props)}</div>
      </div>
    );
  };

  const listingModal = (props) => {
    const { listing } = props;
    return (
      <div
        className="single-listing relative"
        id={`single-listing-${listing.id}`}
        data-testid={`single-listing-${listing.id}`}
      >
        <div className="listing-content">{listingContent(props)}</div>
      </div>
    );
  };

  return isOpen
    ? listingModal({
        ...props,
        isModal: true,
      })
    : listingInline({
        ...props,
        isModal: false,
      });
};

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
