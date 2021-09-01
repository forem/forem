import PropTypes from 'prop-types';

export const organizationPropType = PropTypes.shape({
  id: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  slug: PropTypes.string.isRequired,
  profile_image_90: PropTypes.string.isRequired,
});
