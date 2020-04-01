import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const SecondaryButton = (props) => {
  const { children, ...otherProps } = props;

  return (
    <Button variant="secondary" {...otherProps}>
      {children}
    </Button>
  );
};

SecondaryButton.defaultProps = {
  className: undefined,
  url: undefined,
  buttonType: 'button',
  disabled: false,
};

SecondaryButton.displayName = 'SecondaryButton';

SecondaryButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  as: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
  url: PropTypes.string,
  buttonType: PropTypes.string,
  disabled: PropTypes.bool,
};
