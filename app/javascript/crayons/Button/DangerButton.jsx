import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const DangerButton = ({ children, as = 'button', className }) => (
  <Button variant="danger" as={as} className={className}>
    {children}
  </Button>
);

DangerButton.defaultProps = {
  className: undefined,
};

DangerButton.displayName = 'DangerButton';

DangerButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  as: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
};
