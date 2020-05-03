import PropTypes from 'prop-types';

export const imageManagementPropTypes = PropTypes.shape({
  onExit: PropTypes.func.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
  mainImage: PropTypes.string.isRequired,
  version: PropTypes.string.isRequired,
});
