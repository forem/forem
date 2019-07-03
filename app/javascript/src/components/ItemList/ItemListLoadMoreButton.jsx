// Load more button for item list
import { h } from 'preact';
import { PropTypes } from 'preact-compat';

export const ItemListLoadMoreButton = ({ show, onClick }) => {
  if (!show) {
    return '';
  }

  return (
    <div className="load-more-wrapper">
      <button onClick={onClick} type="button">
        Load More
      </button>
    </div>
  );
};

ItemListLoadMoreButton.propTypes = {
  show: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired,
};
