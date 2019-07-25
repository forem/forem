import PropTypes from 'prop-types';
import { h } from 'preact';
import ListingDate from './rowElements/listingDate';
import Tags from './rowElements/tags';

export const ListingRow = ({ listing }) => {
  const listingLocation = listing.location ? (` ・ ${listing.location}`) : '';

  const bumpedAt = listing.bumped_at.toString();
  // const isExpired = ((Date.now() - new Date(bumpedAt).getTime()) / (1000 * 60 * 60 * 24)) > 30 && (!listing.published)
  const isDraft = ((Date.now() - new Date(bumpedAt).getTime()) / (1000 * 60 * 60 * 24)) < 30 && (!listing.published)
  const draftButton = isDraft
    ? (
      <a
        href={`${`${listing.category}/${listing.slug}`}`}
        className="dashboard-listing-edit-button cta pill yellow"
      >
        DRAFT
      </a>
    ) : (
      ''
    );
  
  const orgName = l =>
    l.organization_id ? (
      <span className="listing-org">{l.author.name}</span>
    ) : (
      ''
    );

  return (
    <div className={`dashboard-listing-row ${isDraft ? 'draft' : ''}`}>
      {orgName(listing)}
      <a href={`${`${listing.category}/${listing.slug}`}`}>
        <h2>{listing.title}</h2>
      </a>
      <ListingDate bumpedAt={listing.bumped_at} updatedAt={listing.updated_at} />
      <span className="dashboard-listing-category">
        <a href={`/listings/${listing.category}/`}>{listing.category}</a>
      </span>
      <Tags tagList={listing.tag_list} />
      <div className="listing-row-actions">
        {/* <a className="dashboard-listing-bump-button cta pill black">BUMP</a> */}
        {draftButton}
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
