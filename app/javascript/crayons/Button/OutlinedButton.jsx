import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const OutlinedButton = ({
  children,
  as = 'button',
  className,
  url,
  buttonType,
}) => (
  <Button
    variant="outlined"
    as={as}
    className={className}
    url={url}
    buttonType={buttonType}
  >
    {children}
  </Button>
);

OutlinedButton.defaultProps = {
  className: undefined,
  url: undefined,
  buttonType: 'button',
};

OutlinedButton.displayName = 'OutlinedButton';

OutlinedButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  as: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
  url: PropTypes.string,
  buttonType: PropTypes.string,
};
