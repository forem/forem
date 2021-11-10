import { h } from 'preact';
import classNames from 'classnames/bind';
import { Icon } from '@crayons';

export const Link = (props) => {
  const {
    children,
    href = '#',
    variant,
    block,
    icon,
    rounded,
    className,
    ...otherProps
  } = props;


  const classes = classNames('c-link', {
    [`c-link--${variant}`]: variant,
    'c-link--icon-left': icon && children,
    'c-link--icon-alone': icon && !children,
    'c-link--block': block,
    'radius-full': rounded,
    [className]: className,
  });

  return (
    <a
      href={href}
      className={classes}
      {...otherProps}
    >
      {icon && <Icon src={icon} className={classNames('c-link__icon')} />}
      {children}
    </a>
  );
};

Link.displayName = 'Link';
