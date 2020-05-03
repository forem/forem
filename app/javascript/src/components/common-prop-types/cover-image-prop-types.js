import PropTypes from 'prop-types';

export const CoverImagePropTypes = PropTypes.shape({
  className: PropTypes.string.isRequired,
  imageSrc: PropTypes.string.isRequired,
  imageAlt: PropTypes.string.isRequired,
});
