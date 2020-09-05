import PropTypes from 'prop-types';
import { h } from 'preact';
import listingPropTypes from './listingPropTypes';
import DropdownMenu from './DropdownMenu';
import TagLinks from './TagLinks';

const Header = ({ listing, currentUserId, onTitleClick, onAddTag }) => {
  const { id, user_id: userId, category, slug, title, bumped_at } = listing;
  const listingDate = bumped_at
    ? new Date(bumped_at.toString()).toLocaleDateString('default', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
      })
    : null;

  return (
    <header className="mb-3">
      <h2 className="fs-2xl fw-bold lh-tight mb-1 pr-8">
        <a
          href={`/listings/${category}/${slug}`}
          data-no-instant
          className="crayons-link"
          onClick={(e) => onTitleClick(e, listing)}
          data-listing-id={id}
        >
          {title}
        </a>
      </h2>

      <div className="single-listing__date" data-testid="single-listing-date">
        {listingDate}
      </div>

      <TagLinks tags={listing.tags} onClick={onAddTag} />

      <DropdownMenu listing={listing} isOwner={currentUserId === userId} />
    </header>
  );
};

Header.propTypes = {
  listing: listingPropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  currentUserId: PropTypes.number,
  onTitleClick: PropTypes.func.isRequired,
};

Header.defaultProps = {
  currentUserId: null,
};

export default Header;
