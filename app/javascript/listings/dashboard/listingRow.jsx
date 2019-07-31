import PropTypes from 'prop-types';
import { h } from 'preact';

export const ListingRow = ({ listing }) => {
  const tagLinks = listing.tag_list.map(tag => (
    <a href={`/listings?t=${tag}`} data-no-instant>
      #{tag}{' '}
    </a>
  ));

  const listingLocation = listing.location ? (` ・ ${listing.location}`) : '';

  const listingDate = listing.bumped_at
    ? new Date(listing.bumped_at.toString()).toLocaleDateString('default', {
        day: '2-digit',
        month: 'short',
      })
    : new Date(listing.updated_at.toString()).toLocaleDateString('default', {
        day: '2-digit',
        month: 'short',
      });

  const orgName = listing.organization_id ? (
    <span className="listing-org">{listing.author.name}</span>
  ) : (
    ''
  );

  return (
    <div className={`dashboard-listing-row ${listing.published ? '' : 'expired'}`}>
      {orgName}
      <a href={`${listing.category}/${listing.slug}`}>
        <h2>{listing.title + (listing.published ? '' : " (expired)")}</h2>
      </a>
      <span className="dashboard-listing-date">
        {listingDate} 
        {listingLocation}
      </span>
      <span className="dashboard-listing-category">
        <a href={`/listings/${listing.category}/`}>{listing.category}</a>
      </span>
      <span className="dashboard-listing-tags">{tagLinks}</span>
      <div className="listing-row-actions">
        {/* <a className="dashboard-listing-bump-button cta pill black">BUMP</a> */}
        <a
          href={`/listings/${listing.id}/edit`}
          className="dashboard-listing-edit-button cta pill green"
        >
          EDIT
        </a>
        {/* <a className="dashboard-listing-delete-button cta pill red">DELETE</a> */}
      </div>
    </div>
  );
};

ListingRow.propTypes = {
  listing: PropTypes.object.isRequired,
};
