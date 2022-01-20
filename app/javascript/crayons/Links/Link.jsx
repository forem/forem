import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';
import { Icon } from '@crayons';

export const Link = (props) => {
  const {
    children,
    href = '#',
    variant = 'default',
    block,
    icon,
    rounded,
    className,
    ...otherProps
  } = props;

  const classes = classNames('c-link', {
    [`c-link--${variant}`]: variant && variant !== 'default',
    'c-link--icon-left': icon && children,
    'c-link--icon-alone': icon && !children,
    'c-link--block': block,
    'radius-full': rounded,
    [className]: className,
  });

  return (
    <a href={href} className={classes} {...otherProps}>
      {icon && (
        <Icon
          src={icon}
          aria-hidden="true"
          focusable="false"
          className="c-link__icon"
        />
      )}
      {children}
    </a>
  );
};

Link.displayName = 'Link';

Link.propTypes = {
  variant: PropTypes.oneOf(['default', 'branded']),
  block: PropTypes.bool,
  rounded: PropTypes.bool,
  href: PropTypes.string.isRequired,
  className: PropTypes.string,
  children: defaultChildrenPropTypes,
  icon: PropTypes.elementType,
};
