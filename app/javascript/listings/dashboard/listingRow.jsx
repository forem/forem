import PropTypes from 'prop-types';
import { h } from 'preact';

export const ListingRow = ({listing}) => {

  const tagLinks = listing.tag_list.map(tag => (
    <a href={`/listings?t=${tag}`} data-no-instant>{tag}</a>
  ));

  const listingDate = (new Date(listing.bumped_at.toString())).toDateString();
  return(
    <div className="dashboard-listing-row">
      <h3>
        <a href={`${listing.category + '/' + listing.slug}`}>
          {listing.title}
        </a>
      </h3>
      <div className="listing-body" dangerouslySetInnerHTML={{ __html: listing.processed_html }} />
      <span className="listing-date">{listingDate} </span>
      <span className="listing-category">{listing.category}</span>
      <span className="dashboard-listing-tags">{tagLinks}</span>
      <div className="dashboard-listing-actions">
        {/* bump button */}
        <a className="dashboard-listing-bump-button">bump</a>
        <a href={`/listings/${listing.id}/edit`} className="dashboard-listing-edit-button">・edit</a>
        {/* delete button */}
        <a className="dashboard-listing-delete-button">・delete</a>
      </div>
    </div>
  );
}

ListingRow.propTypes = {
  listing: PropTypes.object.isRequired,
};
