import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';

export const Indicator = ({
  children,
  variant = 'default',
  extraPadding,
  className,
  ...otherProps
}) => {
  const classes = classNames('c-indicator', {
    [`c-indicator--${variant}`]: variant && variant !== 'default',
    'p-2': extraPadding,
    [className]: className,
  });

  return (
    <span className={classes} {...otherProps}>
      {children}
    </span>
  );
};

Indicator.displayName = 'Indicator';

Indicator.propTypes = {
  variant: PropTypes.oneOf(['default', 'info', 'success', 'warning', 'danger']),
  className: PropTypes.string,
  extraPadding: PropTypes.bool,
};
