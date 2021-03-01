import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const NextPageButton = ({ onClick }) => (
  <div className="flex justify-center">
    <Button variant="secondary" onClick={onClick} type="button">
      Load more...
    </Button>
  </div>
);

NextPageButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};
