import { h } from 'preact';
import PropTypes from 'prop-types';

const ClearQueryButton = ({ onClick, shouldRender }) =>
  shouldRender ? (
    <button type="button" className="classified-search-clear" onClick={onClick}>
      ×
    </button>
  ) : (
    ''
  );

ClearQueryButton.propTypes = {
  onClick: PropTypes.func.isRequired,
  shouldRender: PropTypes.bool.isRequired,
};

export default ClearQueryButton;
