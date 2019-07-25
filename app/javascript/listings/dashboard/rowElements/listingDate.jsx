import PropTypes from 'prop-types';
import { h } from 'preact';

const ListingDate = ({ bumpedAt, updatedAt }) => {

  const listingDate = bumpedAt
    ? new Date(bumpedAt.toString()).toLocaleDateString('default', {
        day: '2-digit',
        month: 'short',
      })
    : new Date(updatedAt.toString()).toLocaleDateString('default', {
        day: '2-digit',
        month: 'short',
      });

  return (
    <span className="dashboard-listing-date">
      {listingDate} 
    </span> 
  )
}

ListingDate.propTypes = {
  bumpedAt: PropTypes.instanceOf(Date).isRequired,
  updatedAt: PropTypes.instanceOf(Date).isRequired,
}

export default ListingDate;