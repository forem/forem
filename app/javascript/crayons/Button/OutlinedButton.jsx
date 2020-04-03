import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const OutlinedButton = (props) => {
  const { children, ...otherProps } = props;

  return (
    <Button variant="outlined" {...otherProps}>
      {children}
    </Button>
  );
};

OutlinedButton.defaultProps = {
  className: undefined,
  url: undefined,
  buttonType: 'button',
  disabled: false,
};

OutlinedButton.displayName = 'OutlinedButton';

OutlinedButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  tagName: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
  url: PropTypes.string,
  buttonType: PropTypes.string,
  disabled: PropTypes.bool,
};
