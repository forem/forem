import PropTypes from 'prop-types';

const tagPropType = PropTypes.shape({
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  following: PropTypes.bool.isRequired,
  bg_color_hex: PropTypes.string.isRequired,
  text_color_hex: PropTypes.string.isRequired,
}).isRequired;

export default tagPropType;
