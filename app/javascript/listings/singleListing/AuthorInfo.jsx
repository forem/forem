import PropTypes from 'prop-types';
import { h } from 'preact';
import listingPropTypes from './listingPropTypes';

const LocationText = ({ location }) => {
  return location ? (
    <a href={`/listings/?q=${location}`}>
      {'・'}
      {location}
    </a>
  ) : (
    ''
  );
};

LocationText.propTypes = {
  location: PropTypes.string,
};

LocationText.defaultProps = {
  location: null,
};

const AuthorInfo = ({ listing, onCategoryClick }) => {
  const { category, location, author = {} } = listing;
  const { username, name } = author;
  return (
    <div className="single-classified-listing-author-info">
      <a
        href={`/listings/${category}`}
        onClick={e => onCategoryClick(e, category)}
        data-no-instant
      >
        {category}
      </a>
      <LocationText location={location} />
      ・
      <a href={`/${username}`}>{name}</a>
    </div>
  );
};

AuthorInfo.propTypes = {
  listing: listingPropTypes.isRequired,
  onCategoryClick: PropTypes.func,
};

AuthorInfo.defaultProps = {
  onCategoryClick: () => {},
};

export default AuthorInfo;
