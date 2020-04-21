import { h } from 'preact';
import PropTypes from 'prop-types';
import { snackbarItemProps } from './SnackbarItem';

export const Snackbar = ({ children = [] }) => (
  <div className={children.length > 0 ? 'crayons-snackbar' : 'hidden'}>
    {children}
  </div>
);

Snackbar.displayName = 'Snackbar';

Snackbar.propTypes = {
  children: PropTypes.arrayOf(snackbarItemProps).isRequired,
};
