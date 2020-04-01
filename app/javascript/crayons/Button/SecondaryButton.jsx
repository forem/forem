import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';
import { Button } from './Button';

export const SecondaryButton = ({
  children,
  as = 'button',
  className,
  url,
  buttonType,
}) => (
  <Button
    variant="secondary"
    as={as}
    className={className}
    url={url}
    buttonType={buttonType}
  >
    {children}
  </Button>
);

SecondaryButton.defaultProps = {
  className: undefined,
  url: undefined,
  buttonType: 'button',
};

SecondaryButton.displayName = 'SecondaryButton';

SecondaryButton.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  as: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
  url: PropTypes.string,
  buttonType: PropTypes.string,
};
