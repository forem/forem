// Load more button for item list
import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const ItemListLoadMoreButton = ({ show, onClick }) => {
  if (!show) {
    return '';
  }

  return (
    <div>
      <Button onClick={onClick} className="w-100" variant="secondary">
        Load more
      </Button>
    </div>
  );
};

ItemListLoadMoreButton.propTypes = {
  show: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired,
};
