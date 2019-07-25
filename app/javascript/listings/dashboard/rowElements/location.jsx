import PropTypes from 'prop-types';
import { h } from 'preact';

const Location = ({ location }) => {

  const listingLocation = location ? (
    <span className="dashboard-listing-date">
      ` ・ 
      {location}
      `
    </span>
    ) : '';

  return (
    {listingLocation} 
  )
}


Location.propTypes = {
  location: PropTypes.string.isRequired,
}

export default Location;