import { h } from 'preact';
import { useState } from 'preact/hooks';
import classNames from 'classnames/bind';

export const Button = (props) => {
  const {
    children,
    variant,
    icon,
    rounded,
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
    [`c-btn--${variant}`]: variant,
    'c-btn--icon-left': icon,
    'c-btn--icon': icon && children,
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
