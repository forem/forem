import PropTypes from 'prop-types';

// Use this whenever you need the standard children prop.
const defaultChildrenPropTypes = PropTypes.oneOfType([
  PropTypes.arrayOf(PropTypes.node),
  PropTypes.node,
]);
export default defaultChildrenPropTypes;
