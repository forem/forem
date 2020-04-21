import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button, ButtonGroup } from '@crayons';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

const snackbarItemProps = {
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
  <div className="crayons-snackbar__item flex">
    <div className="crayons-snackbar__body">{message}</div>
    <div className="crayons-snackbar__actions">
      <ButtonGroup>
        {actions.map(({ text, handler }) => (
          <Button variant="secondary" onClick={handler} key={text}>
            {text}
          </Button>
        ))}
      </ButtonGroup>
    </div>
  </div>
);

SnackbarItem.displayName = 'SnackbarItem';

SnackbarItem.propTypes = snackbarItemProps.isRequired;

export const Snackbar = ({ children = [] }) => (
  <div className={children.length > 0 ? 'crayons-snackbar' : 'hidden'}>
    {children}
  </div>
);

Snackbar.displayName = 'Snackbar';

Snackbar.propTypes = {
  children: PropTypes.arrayOf(snackbarItemProps).isRequired,
};
