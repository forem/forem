import { h } from 'preact';
import PropTypes from 'prop-types';

const ClearQueryButton = ({ onClick }) => (
  <button
    data-testid="clear-query-button"
    type="button"
    className="crayons-btn crayons-btn--ghost absolute right-0"
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
