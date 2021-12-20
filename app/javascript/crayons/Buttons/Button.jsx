import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import classNames from 'classnames/bind';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';
import { Icon } from '@crayons';

export const ButtonNew = (props) => {
  const {
    children,
    variant = 'default',
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
    [`c-btn--${variant}`]: variant && variant !== 'default',
    'c-btn--destructive': destructive && variant !== 'secondary',
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
      {icon && (
        <Icon
          aria-hidden="true"
          focusable="false"
          src={icon}
          className="c-btn__icon"
        />
      )}
      {children}
      {tooltip ? (
        <span
          data-testid="tooltip"
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

ButtonNew.displayName = 'ButtonNew';

ButtonNew.propTypes = {
  children: defaultChildrenPropTypes,
  variant: PropTypes.oneOf(['default', 'primary', 'secondary']),
  rounded: PropTypes.bool,
  destructive: PropTypes.bool,
  type: PropTypes.oneOf(['button', 'submit']),
  className: PropTypes.string,
  tooltip: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
  onKeyUp: PropTypes.func,
  icon: PropTypes.elementType,
};
