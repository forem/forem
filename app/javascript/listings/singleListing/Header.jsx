import PropTypes from 'prop-types';
import { h } from 'preact';
import listingPropTypes from './listingPropTypes';
import DropdownMenu from './DropdownMenu';

const Header = ({ listing, currentUserId, onTitleClick }) => {
  const { id, user_id: userId, category, slug, title } = listing;
  return (
    <h3 className="single-classified-listing-header">
      <a
        href={`/listings/${category}/${slug}`}
        data-no-instant
        onClick={e => onTitleClick(e, listing)}
        data-listing-id={id}
      >
        {title}
      </a>

      <DropdownMenu listing={listing} isOwner={currentUserId === userId} />
    </h3>
  );
};

Header.propTypes = {
  listing: listingPropTypes.isRequired,
  currentUserId: PropTypes.number,
  onTitleClick: PropTypes.func.isRequired,
};

Header.defaultProps = {
  currentUserId: null,
};

export default Header;
