import { h } from 'preact';
import PropTypes from 'prop-types';

const GlobalModalWrapper = ({ children }) => (
  <div className="global-modal">
    <div className="modal-body">{children}</div>
  </div>
);

GlobalModalWrapper.propTypes = {
  children: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.node),
    PropTypes.node,
  ]).isRequired,
};

export default GlobalModalWrapper;
