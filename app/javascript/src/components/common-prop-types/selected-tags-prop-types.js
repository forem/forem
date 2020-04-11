import PropTypes from 'prop-types';

export const selectedTagsPropTypes = PropTypes.shape({
  tags: PropTypes.isRequired,
  onClick: PropTypes.func.isRequired,
  onKeyPress: PropTypes.func.isRequired,
});
