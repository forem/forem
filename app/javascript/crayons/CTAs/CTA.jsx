import { h } from 'preact';
import classNames from 'classnames/bind';
import { Icon } from '@crayons';

export const CTA = (props) => {
  const {
    children,
    href,
    variant = 'default',
    icon,
    rounded,
    className,
    ...otherProps
  } = props;


  const classes = classNames('c-cta', {
    [`c-cta--${variant}`]: variant,
    'c-cta--icon-left': icon && children,
    'c-cta--icon-alone': icon && !children,
    'radius-full': rounded,
    [className]: className,
  });

  return (
    <a
      href={href}
      className={classes}
      {...otherProps}
    >
      {icon && <Icon src={icon} className={classNames('c-cta__icon')} />}
      {children}
    </a>
  );
};

CTA.displayName = 'CTA';
