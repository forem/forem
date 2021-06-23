import PropTypes from 'prop-types';
import { h } from 'preact';
import { DateTime } from '../../shared/components/dateTime';
import { listingPropTypes } from './listingPropTypes';
import { DropdownMenu } from './DropdownMenu';
import { TagLinks } from './TagLinks';

export const Header = ({ listing, currentUserId, onTitleClick, onAddTag }) => {
  const {
    id,
    user_id: userId,
    category,
    slug,
    title,
    bumped_at,
    originally_published_at,
  } = listing;
  const listingDate = bumped_at ? bumped_at : originally_published_at;

  return (
    <div className="mb-3">
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
      <DateTime dateTime={listingDate} className="single-listing__date" />
      <TagLinks tags={listing.tags || listing.tag_list} onClick={onAddTag} />

      <DropdownMenu listing={listing} isOwner={currentUserId === userId} />
    </div>
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
