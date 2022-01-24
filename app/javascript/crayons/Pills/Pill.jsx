import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import classNames from 'classnames/bind';
import { Icon } from '@crayons';
import XIcon from '@images/x.svg';

export const Pill = ({
  children,
  element = 'button',
  href = '#',
  descriptionIcon,
  actionIcon,
  destructiveActionIcon,
  className,
  tooltip,
  onKeyUp,
  ...otherProps
}) => {
  const [suppressTooltip, setSuppressTooltip] = useState(false);

  const handleKeyUp = (event) => {
    onKeyUp?.(event);
    if (!tooltip) {
      return;
    }
    setSuppressTooltip(event.key === 'Escape');
  };

  const Element = element;

  const restOfProps =
    element === 'button'
      ? {
          type: 'button',
          onKeyUp: handleKeyUp,
        }
      : element === 'a' && {
          href,
        };

  const classes = classNames('c-pill', {
    'c-pill--icon-left': descriptionIcon,
    'c-pill--icon-right': actionIcon || destructiveActionIcon,
    'c-pill--icon-right--destructive': destructiveActionIcon,
    'crayons-tooltip__activator': tooltip,
    [className]: className,
  });

  return (
    <Element className={classes} {...otherProps} {...restOfProps}>
      {descriptionIcon && (
        <Icon
          aria-hidden="true"
          focusable="false"
          width={18}
          height={18}
          src={descriptionIcon}
          className="c-pill__icon-left"
        />
      )}
      {children}
      {(actionIcon || destructiveActionIcon) && (
        <Icon
          aria-hidden="true"
          focusable="false"
          width={18}
          height={18}
          src={actionIcon || (destructiveActionIcon && XIcon)}
          className="c-pill__icon-right"
        />
      )}
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
    </Element>
  );
};

Pill.displayName = 'Pill';

Pill.propTypes = {
  children: PropTypes.string.isRequired,
  element: PropTypes.oneOf(['button', 'a', 'span', 'li']),
  className: PropTypes.string,
  descriptionIcon: PropTypes.elementType,
  actionIcon: PropTypes.elementType,
  destructiveActionIcon: PropTypes.bool,
  tooltip: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
};
