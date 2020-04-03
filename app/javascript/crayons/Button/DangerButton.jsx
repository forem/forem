import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const DangerButton = (props) => {
  const { children, ...otherProps } = props;

  return (
    <Button variant="danger" {...otherProps}>
      {children}
    </Button>
  );
};

DangerButton.defaultProps = {
  className: undefined,
  url: undefined,
  buttonType: 'button',
  disabled: false,
};

DangerButton.displayName = 'DangerButton';

DangerButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  tagName: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
  url: PropTypes.string,
  buttonType: PropTypes.string,
  disabled: PropTypes.bool,
};
