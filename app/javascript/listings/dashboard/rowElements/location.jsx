import PropTypes from 'prop-types';
import { h } from 'preact';

const Location = ({ location }) => {
  return <span className="dashboard-listing-date">・{location}</span>;
};

Location.propTypes = {
  location: PropTypes.string.isRequired,
};

export default Location;
