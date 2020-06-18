import { h } from 'preact';
import PropTypes from 'prop-types';

const ClearQueryButton = ({ onClick }) => (
  <button
    data-testid="clear-query-button"
    type="button"
    className="listing-search-clear"
    onClick={onClick}
    id="clear-query-button"
  >
    ×
  </button>
);

ClearQueryButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};

export default ClearQueryButton;
