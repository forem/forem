import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const SecondaryButton = ({ children, as = 'button', className }) => (
  <Button variant="secondary" as={as} className={className}>
    {children}
  </Button>
);

SecondaryButton.defaultProps = {
  className: undefined,
};

SecondaryButton.displayName = 'SecondaryButton';

SecondaryButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  as: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
};
