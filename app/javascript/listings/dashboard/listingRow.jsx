import PropTypes from 'prop-types';
import { h, Fragment } from 'preact';
import { DateTime } from '../../shared/components/dateTime';
import { ListingDate } from './rowElements/listingDate';
import { Tags } from './rowElements/tags';
import { Location } from './rowElements/location';
import { ActionButtons } from './rowElements/actionButtons';

export const ListingRow = ({ listing }) => {
  const bumpedAt = listing.bumped_at ? listing.bumped_at.toString() : null;
  const isExpired =
    bumpedAt && !listing.published
      ? (Date.now() - new Date(bumpedAt).getTime()) / (1000 * 60 * 60 * 24) > 30
      : false;
  const isDraft = bumpedAt ? !isExpired && !listing.published : true;
  const listingUrl = listing.published
    ? `${listing.category}/${listing.slug}`
    : `${listing.id}/edit`;

  const expiryDate = listing.expires_at ? listing.expires_at.toString() : '';

  return (
    <div
      className={`dashboard-listing-row ${isDraft ? 'draft' : ''} ${
        isExpired ? 'expired' : ''
      }`}
      data-listing-id={listing.id}
    >
      {listing.organization_id && (
        <span className="listing-org">{listing.author.name}</span>
      )}
      <a href={listingUrl}>
        <h2>{listing.title + (isExpired ? ' (expired)' : '')}</h2>
      </a>
      <ListingDate
        bumpedAt={listing.bumped_at}
        updatedAt={listing.updated_at}
      />
      {expiryDate && (
        <Fragment>
          {' | Expires on: '}
          <DateTime dateTime={expiryDate} />
        </Fragment>
      )}
      {listing.location && <Location location={listing.location} />}
      <span className="dashboard-listing-category">
        <a href={`/listings/${listing.category}`}>{listing.category}</a>
      </span>
      <Tags tagList={listing.tag_list} />
      <ActionButtons
        isDraft={isDraft}
        listingUrl={`${listing.category}/${listing.slug}`}
        editUrl={`/listings/${listing.id}/edit`}
        deleteConfirmUrl={`/listings/${listing.category}/${listing.slug}/delete_confirm`}
      />
    </div>
  );
};

ListingRow.propTypes = {
  listing: PropTypes.PropTypes.shape({
    title: PropTypes.string.isRequired,
    tag_list: PropTypes.arrayOf(PropTypes.string),
    created_at: PropTypes.instanceOf(Date),
    bumped_at: PropTypes.instanceOf(Date),
    updated_at: PropTypes.instanceOf(Date),
    category: PropTypes.string.isRequired,
    id: PropTypes.number.isRequired,
    user_id: PropTypes.number.isRequired,
    slug: PropTypes.string.isRequired,
    organization_id: PropTypes.number,
    location: PropTypes.string,
    expires_at: PropTypes.bool,
    published: PropTypes.bool.isRequired,
    author: PropTypes.object,
  }).isRequired,
};
