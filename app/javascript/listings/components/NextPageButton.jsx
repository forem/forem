import { h } from 'preact';
import PropTypes from 'prop-types';

const NextPageButton = ({ onClick }) => (
  <div className="listings-load-more-button">
    <button onClick={onClick} type="button">
      Load More Listings
    </button>
  </div>
);

NextPageButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};

export default NextPageButton;
