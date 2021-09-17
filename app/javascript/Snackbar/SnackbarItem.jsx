import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../common-prop-types';
import { Button } from '@crayons';

export const snackbarItemProps = {
  children: defaultChildrenPropTypes.isRequired,
  actions: PropTypes.arrayOf(
    PropTypes.shape({
      message: PropTypes.string.isRequired,
      handler: PropTypes.func.isRequired,
      lifespan: PropTypes.number.isRequired,
    }),
  ),
};

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

SnackbarItem.propTypes = snackbarItemProps.isRequired;
