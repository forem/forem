import { h } from 'preact';
import classNames from 'classnames/bind';
import PropTypes from 'prop-types';
// import { ButtonNew as Button, Link } from '@crayons';

export const Tab = ({
  className,
  current,
  elements,
  fitted,
  children,
  ...otherProps
}) => {
  const classes = classNames('c-tab', {
    'c-tab--fitted': fitted,
    [className]: className,
  });

  return elements === 'buttons' ? (
    <button
      type="button"
      className={classes}
      aria-pressed={!!current}
      {...otherProps}
    >
      {children}
    </button>
  ) : (
    <a className={classes} aria-current={current && 'page'} {...otherProps}>
      {children}
    </a>
  );
};

Tab.displayName = 'Tab';

Tab.propTypes = {
  className: PropTypes.string,
  current: PropTypes.bool,
  elements: PropTypes.oneOf(['buttons', 'links']),
  fitted: PropTypes.bool,
};
