import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';
import { Button } from '@crayons/Button/Button';

export const ClearQueryButton = ({ onClick }) => (
  <Button
    data-testid="clear-query-button"
    variant="ghost"
    className="absolute right-0"
    onClick={onClick}
    id="clear-query-button"
  >
    {i18next.t('common.close')}
  </Button>
);

ClearQueryButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};
