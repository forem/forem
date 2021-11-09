import { h } from 'preact';
import { useState } from 'preact/hooks';
import classNames from 'classnames/bind';
import { Icon } from '@crayons';

export const Button = (props) => {
  const {
    children,
    primary,
    icon,
    rounded,
    destructive,
    type = 'button',
    className,
    tooltip,
    onKeyUp,
    ...otherProps
  } = props;

  const [suppressTooltip, setSuppressTooltip] = useState(false);

  const handleKeyUp = (event) => {
    onKeyUp?.(event);
    if (!tooltip) {
      return;
    }
    setSuppressTooltip(event.key === 'Escape');
  };

  const classes = classNames('c-btn', {
    'c-btn--primary': primary,
    'c-btn--destructive': destructive,
    'c-btn--icon-left': icon && children,
    'c-btn--icon-alone': icon && !children,
    'crayons-tooltip__activator': tooltip,
    'radius-full': rounded,
    [className]: className,
  });

  return (
    <button
      type={type}
      className={classes}
      onKeyUp={handleKeyUp}
      {...otherProps}
    >
      {icon && <Icon src={icon} className={classNames('c-btn__icon')} />}
      {children}
      {tooltip ? (
        <span
          className={classNames('crayons-tooltip__content', {
            'crayons-tooltip__suppressed': suppressTooltip,
          })}
        >
          {tooltip}
        </span>
      ) : null}
    </button>
  );
};

Button.displayName = 'Button';
