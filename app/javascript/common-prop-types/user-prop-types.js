import PropTypes from 'prop-types';

export const userPropTypes = PropTypes.shape({
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  profile_image_url: PropTypes.string.isRequired,
  summary: PropTypes.string.isRequired,
});
