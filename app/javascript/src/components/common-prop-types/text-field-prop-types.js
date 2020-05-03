import PropTypes from 'prop-types';

export const textFieldPropTypes = PropTypes.shape({
  label: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  onKeyUp: PropTypes.func.isRequired,
});
