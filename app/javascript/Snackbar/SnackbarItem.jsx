import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const SnackbarItem = ({ message, actions = [] }) => (
  <div className="crayons-snackbar__item flex" data-testid="snackbar">
    <div className="crayons-snackbar__body" role="alert">
      {message}
    </div>
    <div className="crayons-snackbar__actions">
      {actions.map(({ text, handler }) => (
        <Button variant="ghost-success" inverted onClick={handler} key={text}>
          {text}
        </Button>
      ))}
    </div>
  </div>
);

SnackbarItem.displayName = 'SnackbarItem';

SnackbarItem.propTypes = {
  message: PropTypes.string.isRequired,
  actions: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string.isRequired,
      handler: PropTypes.func.isRequired,
    }),
  ),
};
