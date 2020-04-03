import { h } from 'preact';
import PropTypes from 'prop-types';

const ClearQueryButton = ({ onClick }) => (
  <button type="button" className="classified-search-clear" onClick={onClick}>
    ×
  </button>
);

ClearQueryButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};

export default ClearQueryButton;
