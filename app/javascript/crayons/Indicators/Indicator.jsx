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

Indicator.displayName = 'CTA';

Indicator.propTypes = {
  variant: PropTypes.oneOf(['default', 'info', 'success', 'warning', 'danger']),
  href: PropTypes.string.isRequired,
  className: PropTypes.string,
  relaxed: PropTypes.bool,
};
