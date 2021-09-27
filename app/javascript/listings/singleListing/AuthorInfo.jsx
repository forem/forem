import PropTypes from 'prop-types';
import { h } from 'preact';
import { listingPropTypes } from './listingPropTypes';

const LocationText = ({ location }) => {
  return location ? (
    <a
      data-testid="single-listing-location"
      className="crayons-link crayons-link--secondary"
      href={`/listings/?q=${location}`}
    >
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

export const AuthorInfo = ({ listing, onCategoryClick }) => {
  const { category, location, author = {} } = listing;
  const { username, name, profile_image_90 } = author;
  return (
    <div className="fs-s flex items-center">
      <a
        href={`/${username}`}
        className="crayons-avatar crayons-avatar--l mr-2"
      >
        <img
          src={profile_image_90}
          alt={name}
          width="32"
          height="32"
          className="crayons-avatar__image"
          loading="lazy"
        />
      </a>

      <div>
        <a href={`/${username}`} className="crayons-link fw-medium">
          {name}
        </a>
        <p className="fs-xs">
          <a
            href={`/listings/${category}`}
            onClick={(e) => onCategoryClick(e, category)}
            data-no-instant
            className="crayons-link crayons-link--secondary"
          >
            {category}
          </a>
          <LocationText location={location} />
        </p>
      </div>
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
