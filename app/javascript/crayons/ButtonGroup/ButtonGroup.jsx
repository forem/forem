import { h } from 'preact';
import PropTypes from 'prop-types';

export const ButtonGroup = ({ children }) => (
  <div role="presentation" className="crayons-btn-group">
    {children}
  </div>
);

ButtonGroup.displayName = 'ButtonGroup';

ButtonGroup.propTypes = {
  children: PropTypes.arrayOf(
    PropTypes.oneOfType([PropTypes.object, PropTypes.bool]),
  ).isRequired,
};
