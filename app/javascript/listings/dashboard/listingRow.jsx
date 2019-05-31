import PropTypes from 'prop-types';
import { h } from 'preact';

export const ListingRow = ({listing}) => {

  const tagLinks = listing.tag_list.map(tag => (
    <a href={`/listings?t=${tag}`} onClick={e => onAddTag(e, tag)} data-no-instant>{tag}</a>
  ));

  const listingDate = new Date(listing.bumped_at.toString());
  const listingDateTag = (<p>{`${listingDate}`}</p>)
  console.log(listingDate)
  return(
    <div className='' id=''>
      <h3>
        <a href="">
          {listing.title}
        </a>
      </h3>
      <a href={`/${listing.author.username}`} >{listing.author.name}</a>
      {listingDateTag}
      <div className="">{tagLinks}</div>
      <a href={`/listings/${listing.id}/edit`} className="classified-listing-edit-button">・edit</a>
    </div>
  );
}

ListingRow.propTypes = {
  listing: PropTypes.object.isRequired,
};
