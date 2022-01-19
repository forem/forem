import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';

export const Indicator = (props) => {
  const {
    children,
    variant = 'default',
    relaxed,
    className,
    ...otherProps
  } = props;

  const classes = classNames('c-indicator', {
    [`c-indicator--${variant}`]: variant && variant !== 'default',
    'c-indicator--relaxed': relaxed,
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
  relaxed: PropTypes.bool,
};
