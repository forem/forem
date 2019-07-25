import PropTypes from 'prop-types';
import { h } from 'preact';
import ListingDate from './rowElements/listingDate';
import Tags from './rowElements/tags';
import Location from './rowElements/location';
import ActionButtons from './rowElements/actionButtons';

export const ListingRow = ({ listing }) => {
  const bumpedAt = listing.bumped_at.toString();
  // const isExpired = ((Date.now() - new Date(bumpedAt).getTime()) / (1000 * 60 * 60 * 24)) > 30 && (!listing.published)
  const isDraft = ((Date.now() - new Date(bumpedAt).getTime()) / (1000 * 60 * 60 * 24)) < 30 && (!listing.published)
  const listingUrl = `${`${listing.category}/${listing.slug}`}`
  const editUrl = `/listings/${listing.id}/edit`;

  const orgName = l =>
    l.organization_id ? (
      <span className="listing-org">{l.author.name}</span>
    ) : (
      ''
    );

  return (
    <div className={`dashboard-listing-row ${isDraft ? 'draft' : ''}`}>
      {orgName(listing)}
      <a href={listingUrl}>
        <h2>{listing.title}</h2>
      </a>
      <ListingDate bumpedAt={listing.bumped_at} updatedAt={listing.updated_at} />
      {listing.location && <Location location={listing.location} />}
      <span className="dashboard-listing-category">
        <a href={`/listings/${listing.category}/`}>{listing.category}</a>
      </span>
      <Tags tagList={listing.tag_list} />
      <ActionButtons isDraft={isDraft} listingUrl={listingUrl} editUrl={editUrl} />
    </div>
  );
};

ListingRow.propTypes = {
  listing: PropTypes.object.isRequired,
};
