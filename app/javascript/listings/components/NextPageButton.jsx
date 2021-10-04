import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';
import { Button } from '@crayons';

export const NextPageButton = ({ onClick }) => (
  <div className="flex justify-center">
    <Button variant="secondary" onClick={onClick} type="button">
      {i18next.t('listings.more')}
    </Button>
  </div>
);

NextPageButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};
