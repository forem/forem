import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';

export const Pill = ({
  children,
  element = 'button',
  className,
  ...otherProps
}) => {
  const Element = element;

  const classes = classNames('c-pill', {
    [className]: className,
  });

  return (
    <Element className={classes} {...otherProps}>
      {children}
    </Element>
  );
};

Pill.displayName = 'Pill';

Pill.propTypes = {
  element: PropTypes.oneOf(['button', 'a', 'span', 'li']),
  className: PropTypes.string,
};
