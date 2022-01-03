import PropTypes from 'prop-types';

// Use this whenever you need the standard children prop.
export const defaultChildrenPropTypes = PropTypes.oneOfType([
  PropTypes.arrayOf(PropTypes.node),
  PropTypes.node,
  PropTypes.object,
  PropTypes.arrayOf(PropTypes.object),
]);
